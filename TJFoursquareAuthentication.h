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
                              completion:(void (^)(NSString *_Nullable accessToken))completion;

+ (BOOL)tryHandleNativeAuthenticationWithURL:(NSURL *const)url;

@end

NS_ASSUME_NONNULL_END
