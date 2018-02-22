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

#import "FSViewController.h"
#import "TJFoursquareAuthentication.h"

@interface FSViewController ()

@property (nonatomic) NSString *latestAccessCode;

@end

@implementation FSViewController

- (void)connectTapped:(id)sender {

    [self dismissKeyboard:nil];
    
    [TJFoursquareAuthentication authenticateWithClientIdentifier:self.clientIdField.text
                                                     redirectURI:[NSURL URLWithString:self.callbackUrlField.text]
                                                    clientSecret:self.clientSecretField.text
                                                      completion:^(NSString * _Nullable accessToken) {
                                                          if (accessToken.length > 0) {
                                                              self.resultLabel.text = [NSString stringWithFormat:@"Token: %@", accessToken];
                                                          } else {
                                                              self.resultLabel.text = @"Auth error";
                                                          }
                                                      }];
}

- (void)handleURL:(NSURL *)url
{
    if ([TJFoursquareAuthentication tryHandleAuthenticationCallbackWithURL:url]) {
        self.resultLabel.text = @"Handled incoming URL";
    }
}

- (void)dismissKeyboard:(id)sender {
    [self.clientIdField resignFirstResponder];
    [self.callbackUrlField resignFirstResponder];
    [self.clientSecretField resignFirstResponder];
}

@end
