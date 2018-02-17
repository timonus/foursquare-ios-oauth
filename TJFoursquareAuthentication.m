//
//  TJFoursquareAuthentication.m
//  Quotidian
//
//  Created by Tim Johnsen on 2/16/18.
//

#import "TJFoursquareAuthentication.h"
#import <SafariServices/SafariServices.h>

@implementation TJFoursquareAuthentication

+ (void)authenticateWithClientIdentifier:(NSString *const)clientIdentifier
                             redirectURI:(NSURL *const)redirectURI
                            clientSecret:(NSString *const)clientSecret
                              completion:(void (^)(NSString *))completion
{
    NSURLComponents *const urlComponents = [NSURLComponents componentsWithString:@"foursquareauth://authorize"];
    urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:clientIdentifier],
                                 [NSURLQueryItem queryItemWithName:@"v" value:@"20130509"],
                                 [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURI.absoluteString],
                                 ];
    
    // Reference needs to be held as long as this is in progress, otherwise the UI disappears.
    static id session = nil;
    
    [[UIApplication sharedApplication] openURL:urlComponents.URL
                                       options:@{}
                             completionHandler:^(BOOL success) {
                                 if (!success) {
                                     if (@available(iOS 11.0, *)) {
                                         NSURLComponents *const urlComponents = [NSURLComponents componentsWithString:@"https://foursquare.com/oauth2/authenticate"];
                                         urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:clientIdentifier],
                                                                      [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"],
                                                                      [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURI.absoluteString],
                                                                      ];
                                         session = [[SFAuthenticationSession alloc] initWithURL:urlComponents.URL
                                                                              callbackURLScheme:redirectURI.scheme
                                                                              completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                                                                                  // Process results.
                                                                                  [self tryHandleNativeAuthenticationWithURL:callbackURL
                                                                                                            clientIdentifier:clientIdentifier
                                                                                                                 redirectURI:redirectURI
                                                                                                                clientSecret:clientSecret
                                                                                                                  completion:completion];
                                                                                  // Break reference so session is deallocated.
                                                                                  session = nil;
                                                                              }];
                                         [(SFAuthenticationSession *)session start];
                                     } else {
                                         completion(nil);
                                     }
                                 }
                             }];
}

+ (BOOL)tryHandleNativeAuthenticationWithURL:(NSURL *const)url
                            clientIdentifier:(NSString *const)clientIdentifier
                                 redirectURI:(NSURL *const)redirectURI
                                clientSecret:(NSString *const)clientSecret
                                  completion:(void (^)(NSString *))completion
{
    BOOL handledURL = NO;
    if ([url.absoluteString hasPrefix:redirectURI.absoluteString]) {
        NSURLComponents *const components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        NSString *code = nil;
        for (NSURLQueryItem *queryItem in components.queryItems) {
            if ([queryItem.name isEqualToString:@"code"]) {
                code = queryItem.value;
                break;
            }
        }
        
        if (code) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"https://foursquare.com/oauth2/access_token"];
            urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:clientIdentifier],
                                         [NSURLQueryItem queryItemWithName:@"client_secret" value:clientSecret],
                                         [NSURLQueryItem queryItemWithName:@"grant_type" value:@"authorization_code"],
                                         [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURI.absoluteString],
                                         [NSURLQueryItem queryItemWithName:@"code" value:code],
                                         ];
            [[[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]] dataTaskWithURL:urlComponents.URL
                                                                                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                                                                  NSString *accessToken = nil;
                                                                                                                  if (data.length > 0) {
                                                                                                                      const id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                                                            options:0
                                                                                                                                                                              error:nil];
                                                                                                                      if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                                                                                                                          accessToken = jsonObject[@"access_token"];
                                                                                                                      }
                                                                                                                  }
                                                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                      completion(accessToken);
                                                                                                                  });
                                                                                                              }] resume];
        } else {
            completion(nil);
        }
        
        handledURL = YES;
    }
    return handledURL;
}

@end
