//
//  TJFoursquareAuthentication.h
//  Quotidian
//
//  Created by Tim Johnsen on 2/16/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TJFoursquareAuthentication : NSObject

/**
* Invoke this to initiate auth
* @param clientIdentifier Your registered Foursquare client identifier.
* @param clientIdentifier Your registered Foursquare redirect URI.
* @param clientIdentifier Foursquare client secret.
* @param completion Block invoked when auth is complete. @c accessToken will be @c nil if auth wasn't completed.
*/
+ (void)authenticateWithClientIdentifier:(NSString *const)clientIdentifier
                             redirectURI:(NSURL *const)redirectURI
                            clientSecret:(NSString *const)clientSecret
                              completion:(void (^)(NSString *_Nullable accessToken))completion API_AVAILABLE(ios(8.0));

/// Invoke this from your app delegate's implementation of -application:openURL:options:, returns whether or not the URL was a completion callback to Foursquare auth.
+ (BOOL)tryHandleAuthenticationCallbackWithURL:(NSURL *const)url API_AVAILABLE(ios(8.0));

@end

NS_ASSUME_NONNULL_END
