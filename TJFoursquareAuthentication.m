//
//  TJFoursquareAuthentication.m
//  Quotidian
//
//  Created by Tim Johnsen on 2/16/18.
//

#import "TJFoursquareAuthentication.h"
#import <AuthenticationServices/AuthenticationServices.h>
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
#import <SafariServices/SafariServices.h>
#endif

// DO NOT mark as Obj-C direct, will lead to exceptions.
@interface TJFoursquareAuthenticatorWebAuthenticationPresentationContextProvider : NSObject

@end

@implementation TJFoursquareAuthenticatorWebAuthenticationPresentationContextProvider

#pragma mark - ASWebAuthenticationPresentationContextProviding

+ (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0))
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[UIApplication sharedApplication] keyWindow];
#pragma clang diagnostic pop
}

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@interface TJFoursquareAuthentication ()

@property (nonatomic, copy, class, setter=tj_setClientIdentifier:) NSString *tj_clientIdentifier;
@property (nonatomic, class, setter=tj_setRedirectURI:) NSURL *tj_redirectURI;
@property (nonatomic, copy, class, setter=tj_setClientSecret:) NSString *tj_clientSecret;
@property (nonatomic, copy, class, setter=tj_setCompletion:) void (^tj_completion)(NSString *accessToken);

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@implementation TJFoursquareAuthentication

#pragma mark - Properties

static NSString *_tj_clientIdentifier;
static NSURL *_tj_redirectURI;
static NSString *_tj_clientSecret;
static void (^_tj_completion)(NSString *accessToken);

+ (void)tj_setClientIdentifier:(NSString *)tj_clientIdentifier
{
    _tj_clientIdentifier = tj_clientIdentifier;
}

+ (void)tj_setRedirectURI:(NSURL *)tj_redirectURI
{
    _tj_redirectURI = tj_redirectURI;
}

+ (void)tj_setClientSecret:(NSString *)tj_clientSecret
{
    _tj_clientSecret = tj_clientSecret;
}

+ (void)tj_setCompletion:(void (^)(NSString *))tj_completion
{
    _tj_completion = tj_completion;
}

+ (NSString *)tj_clientIdentifier
{
    return _tj_clientIdentifier;
}

+ (NSURL *)tj_redirectURI
{
    return _tj_redirectURI;
}

+ (NSString *)tj_clientSecret
{
    return _tj_clientSecret;
}

+ (void (^)(NSString *))tj_completion
{
    return _tj_completion;
}

#pragma mark - Authentication

+ (void)authenticateWithClientIdentifier:(NSString *const)clientIdentifier
                             redirectURI:(NSURL *const)redirectURI
                            clientSecret:(NSString *const)clientSecret
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
             presentationContextProvider:(id<ASWebAuthenticationPresentationContextProviding>)presentationContextProvider
#pragma clang diagnostic pop
                              completion:(void (^)(NSString *))completion
{
    [self authenticateUsingSafariWithClientIdentifier:clientIdentifier
                                          redirectURI:redirectURI
                                         clientSecret:clientSecret
                          presentationContextProvider:presentationContextProvider
                                           completion:completion];
}

+ (void)authenticateUsingSafariWithClientIdentifier:(NSString *const)clientIdentifier
                                        redirectURI:(NSURL *const)redirectURI
                                       clientSecret:(NSString *const)clientSecret
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
                        presentationContextProvider:(id<ASWebAuthenticationPresentationContextProviding>)presentationContextProvider
#pragma clang diagnostic pop
                                         completion:(void (^)(NSString *))completion
{
    NSURLComponents *const urlComponents = [NSURLComponents componentsWithString:@"https://foursquare.com/oauth2/authenticate"];
    urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"client_id" value:clientIdentifier],
                                 [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"],
                                 [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURI.absoluteString],
                                 ];
    NSURL *const url = urlComponents.URL;
    
    // Reference needs to be held as long as this is in progress, otherwise the UI disappears.
    static id session;
    void (^completionHandler)(NSURL *, NSError *) = ^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        // Process results.
        [self tryHandleAuthenticationCallbackWithURL:callbackURL
                                    clientIdentifier:clientIdentifier
                                         redirectURI:redirectURI
                                        clientSecret:clientSecret
                                          completion:completion];
        // Break reference so session is deallocated.
        session = nil;
    };
    if (@available(iOS 12.0, *)) {
        session = [[ASWebAuthenticationSession alloc] initWithURL:url
                                                callbackURLScheme:redirectURI.scheme
                                                completionHandler:completionHandler];
        if (@available(iOS 13.0, *)) {
            [(ASWebAuthenticationSession *)session setPresentationContextProvider:presentationContextProvider ?: (id<ASWebAuthenticationPresentationContextProviding>)[TJFoursquareAuthenticatorWebAuthenticationPresentationContextProvider class]];
        }
        [(ASWebAuthenticationSession *)session start];
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
    } else if (@available(iOS 11.0, *)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        session = [[SFAuthenticationSession alloc] initWithURL:url
                                             callbackURLScheme:redirectURI.scheme
                                             completionHandler:completionHandler];
        [(SFAuthenticationSession *)session start];
#pragma clang diagnostic pop
#endif
    } else {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    [self tj_setClientIdentifier:clientIdentifier];
                    [self tj_setRedirectURI:redirectURI];
                    [self tj_setClientSecret:clientSecret];
                    [self tj_setCompletion:completion];
                } else {
                    completion(nil);
                }
            }];
#if !defined(__IPHONE_10_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0
        } else {
            [self setTj_clientIdentifier:clientIdentifier];
            [self setTj_redirectURI:redirectURI];
            [self setTj_clientSecret:clientSecret];
            [self setTj_completion:completion];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] openURL:url];
#pragma clang diagnostic pop
#endif
        }
    }
}

+ (BOOL)tryHandleAuthenticationCallbackWithURL:(NSURL *const)url
{
    return [self tryHandleAuthenticationCallbackWithURL:url
                                       clientIdentifier:[self tj_clientIdentifier]
                                            redirectURI:[self tj_redirectURI]
                                           clientSecret:[self tj_clientSecret]
                                             completion:[self tj_completion]];
}

+ (BOOL)tryHandleAuthenticationCallbackWithURL:(NSURL *const)url
                              clientIdentifier:(NSString *const)clientIdentifier
                                   redirectURI:(NSURL *const)redirectURI
                                  clientSecret:(NSString *const)clientSecret
                                    completion:(void (^)(NSString *))completion
{
    BOOL handledURL = NO;
    if (redirectURI && [url.absoluteString hasPrefix:redirectURI.absoluteString]) {
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
        
        [self tj_setClientIdentifier:nil];
        [self tj_setRedirectURI:nil];
        [self tj_setClientSecret:nil];
        [self tj_setCompletion:nil];
        
        handledURL = YES;
    }
    return handledURL;
}

@end
