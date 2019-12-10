# FSOAuth / TJFoursquareAuthentication

This is a hard fork of the [FSOAuth project](https://github.com/foursquare/foursquare-ios-oauth). While FSOAuth uses older APIs and is targeted at mass usage even in older clients, `TJFoursquareAuthentication` was rewritten to leverage new APIs and be a bit cleaner.

## Usage

1. You'll need to register a URL scheme for your app.
1. You'll need to register your app in the [Foursquare developer portal](http://foursquare.com/developers/apps) as described in [FSOAuth's instructions](https://github.com/foursquare/foursquare-ios-oauth#setting-up-fsoauth-with-your-app). This will yield a client identifier and client secret for your app. You should use the URL scheme from step 1 with a unique path, I recommend something like `your-apps-url-scheme://fsoauth`.
3. Add `foursquareauth` to your app's info.plist's `LSApplicationQueriesSchemes` array. (Optional, but provides a better experience for those running OS versions prior to iOS 10.0).
4. Before you can authenticate, you should include a call to `+tryHandleAuthenticationCallbackWithURL:` in your app delegate's `-application:openURL:options:` implementation like so.

```
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options
{
    if ([TJFoursquareAuthentication tryHandleAuthenticationCallbackWithURL:url]) {
        // This is an auth callback, bail.
        return YES;
    } else {
        // Carry on with other URL handling
    }
}
```

5. To initiate authentication, call `+authenticateWithClientIdentifier:redirectURI:clientSecret:completion:` passing in the client identifier, client secret, and redirect URI you received from step 2.
6. Once complete, the completion block will be invoked on the main queue. Upon success, `accessToken` will be populated in this block.

## Notes

- `TJFoursquareAuthentication` is compatible with iOS 8 and above.
- `TJFoursquareAuthentication` supports app-to-app auth with the Foursquare app.
- `TJFoursquareAuthentication` will fall back to using `ASWebAuthenticationSession` or `SFAuthenticationSession` depending on iOS version if app-to-app auth isn't available. On older iOS versions it will launch Safari.app to perform auth.