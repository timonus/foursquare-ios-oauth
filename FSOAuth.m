//
// Copyright 2013 Foursquare
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FSOAuth.h"

#define kFoursquareOAuthRequiredVersion @"20130509"
#define kFoursquareAppStoreURL @"https://itunes.apple.com/app/foursquare/id306934924?mt=8"
#define kFoursquareAppStoreID @306934924

@implementation FSOAuth

+ (FSOAuth *)shared {
    static FSOAuth *oauthInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oauthInstance = [[FSOAuth alloc] init];
    });
    
    return oauthInstance;
}

- (FSOAuthStatusCode)authorizeUserUsingClientId:(NSString *)clientID
                        nativeURICallbackString:(NSString *)nativeURICallbackString
                           allowShowingAppStore:(BOOL)allowShowingAppStore
                      presentFromViewController:(UIViewController *)presentFromViewController {
    if ([clientID length] <= 0) {
        return FSOAuthStatusErrorInvalidClientID;
    }

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    BOOL hasNativeCallback = ([nativeURICallbackString length] > 0);
    
    if (!hasNativeCallback) {
        return FSOAuthStatusErrorInvalidCallback;
    }

    BOOL isOnIOS9OrLater = NO;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 90000)
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        NSOperatingSystemVersion minVersion;
        minVersion.majorVersion = 9;
        minVersion.minorVersion = 0;
        minVersion.patchVersion = 0;
        if ([processInfo isOperatingSystemAtLeastVersion:minVersion]) {
            isOnIOS9OrLater = YES;
        }
    }
#endif
    
    if (!isOnIOS9OrLater && !hasNativeCallback) {
        return FSOAuthStatusErrorInvalidCallback;
    }

    if (!isOnIOS9OrLater) {
        if (![sharedApplication canOpenURL:[NSURL URLWithString:@"foursquare://"]]) {
            return FSOAuthStatusErrorFoursquareNotInstalled;
        }
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:@"foursquareauth://authorize"];
    components.queryItems = @[
                              [NSURLQueryItem queryItemWithName:@"client_id" value:clientID],
                              [NSURLQueryItem queryItemWithName:@"v" value:kFoursquareOAuthRequiredVersion],
                              [NSURLQueryItem queryItemWithName:@"redirect_uri" value:nativeURICallbackString]
                              ];
    NSURL *authURL = components.URL;
    
    if (![sharedApplication canOpenURL:authURL]) {
        return FSOAuthStatusErrorFoursquareOAuthNotSupported;
    }
    
    [sharedApplication openURL:authURL];
    
    return FSOAuthStatusSuccess;
}

- (FSOAuthErrorCode)errorCodeForString:(NSString *)value {
    if ([value isEqualToString:@"invalid_request"]) {
        return FSOAuthErrorInvalidRequest;
    }
    else if ([value isEqualToString:@"invalid_client"]) {
        return FSOAuthErrorInvalidClient;
    }
    else if ([value isEqualToString:@"invalid_grant"]) {
        return FSOAuthErrorInvalidGrant;
    }
    else if ([value isEqualToString:@"unauthorized_client"]) {
        return FSOAuthErrorUnauthorizedClient;
    }
    else if ([value isEqualToString:@"unsupported_grant_type"]) {
        return FSOAuthErrorUnsupportedGrantType;
    }
    else {
        return FSOAuthErrorUnknown;
    }
}

- (NSString *)accessCodeForFSOAuthURL:(NSURL *)url error:(FSOAuthErrorCode *)errorCode {
    NSString *accessCode = nil;
    
    if (errorCode != NULL) {
        *errorCode = FSOAuthErrorUnknown;
    }
    
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES] queryItems];
    
    for (NSURLQueryItem *queryItem in queryItems) {
        
        if ([queryItem.name isEqualToString:@"code"]) {
            accessCode = queryItem.value;
            
            if (errorCode != NULL) {
                if (*errorCode == FSOAuthErrorUnknown) { // don't clobber any previously found real error value
                    *errorCode = FSOAuthErrorNone;
                }
            }
        }
        else if ([queryItem.name isEqualToString:@"error"]) {
            if (errorCode != NULL) {
                *errorCode = [self errorCodeForString:queryItem.value];
            }
        }
    }
    
    return accessCode;
}

- (void)requestAccessTokenForCode:(NSString *)accessCode clientId:(NSString *)clientID callbackURIString:(NSString *)callbackURIString clientSecret:(NSString *)clientSecret completionBlock:(FSTokenRequestCompletionBlock)completionBlock {
    if ([accessCode length] > 0
        && [clientID length] > 0
        && [callbackURIString length] > 0
        && [clientSecret length] > 0) {
        
        NSURLComponents *components = [NSURLComponents componentsWithString:@"https://foursquare.com/oauth2/access_token"];
        components.queryItems = @[
                                  [NSURLQueryItem queryItemWithName:@"client_id" value:clientID],
                                  [NSURLQueryItem queryItemWithName:@"client_secret" value:clientSecret],
                                  [NSURLQueryItem queryItemWithName:@"grant_type" value:@"authorization_code"],
                                  [NSURLQueryItem queryItemWithName:@"redirect_uri" value:callbackURIString],
                                  [NSURLQueryItem queryItemWithName:@"code" value:accessCode]
                                  ];
        
        [[[NSURLSession sharedSession] dataTaskWithURL:components.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString *accessToken = nil;
            BOOL requestCompleted = NO;
            FSOAuthErrorCode errorCode = FSOAuthErrorUnknown;
            if (data && [[response MIMEType] isEqualToString:@"application/json"]) {
                id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *jsonDict = (NSDictionary *)jsonObj;
                    
                    if (jsonDict[@"error"]) {
                        errorCode = [self errorCodeForString:jsonDict[@"error"]];
                    } else {
                        error = FSOAuthErrorNone;
                    }
                    
                    accessToken = jsonDict[@"access_token"];
                    requestCompleted = YES;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(accessToken, requestCompleted, errorCode);
            });
        }] resume];
    }
}

@end
