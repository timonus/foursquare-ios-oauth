//
//  TJFoursquareAuthentication.h
//  Quotidian
//
//  Created by Tim Johnsen on 2/16/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TJFoursquareAuthentication : NSObject

+ (void)authenticateWithClientIdentifier:(NSString *const)clientIdentifier
                             redirectURI:(NSURL *const)redirectURI
                            clientSecret:(NSString *const)clientSecret
                              completion:(void (^)(NSString *_Nullable accessToken))completion API_AVAILABLE(ios(8.0));

+ (BOOL)tryHandleAuthenticationCallbackWithURL:(NSURL *const)url API_AVAILABLE(ios(8.0));

@end

NS_ASSUME_NONNULL_END
