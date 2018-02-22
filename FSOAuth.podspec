Pod::Spec.new do |s|
  s.name         = "TJFoursquareAuthentication"
  s.version      = "1.0"
  s.summary      = "TJFoursquareAuthentication makes it easy for users of your app to connect to Foursquare."
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.author       = { "Tim Johnsen" => "tijoinc@gmail.com" }
  s.source       = { :git => "https://github.com/foursquare/foursquare-ios-oauth.git",:tag => '1.3' }
  s.platform     = :ios
  s.source_files = 'TJFoursquareAuthentication.{h,m}'
  s.requires_arc = true
end
