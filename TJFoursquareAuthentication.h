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
                              completion:(void (^)(NSString *_Nullable accessToken))completion API_AVAILABLE(ios(10.0));

+ (BOOL)tryHandleNativeAuthenticationWithURL:(NSURL *const)url
                                  completion:(void (^)(NSString *_Nullable accessToken))completion;

@end

NS_ASSUME_NONNULL_END
