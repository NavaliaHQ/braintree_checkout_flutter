#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint braintree_checkout_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'braintree_checkout_flutter'
  s.version          = '2.1.0'
  s.summary          = 'Flutter plugin for Braintree PayPal, Venmo, card tokenization and 3D Secure.'
  s.description      = <<-DESC
Flutter plugin for Braintree PayPal, Venmo, card tokenization and 3D Secure.
                       DESC
  s.homepage         = 'https://github.com/NavaliaHQ/braintree_checkout_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'NavaliaHQ'
  s.source           = { :path => '.' }
  s.source_files = 'braintree_checkout_flutter/Sources/braintree_checkout_flutter/**/*.swift'
  s.resource_bundles = {
    'braintree_checkout_flutter_privacy' => ['braintree_checkout_flutter/Sources/braintree_checkout_flutter/PrivacyInfo.xcprivacy']
  }
  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.dependency 'Flutter'
  s.dependency 'Braintree/Venmo', '6.30.0'
  s.dependency 'Braintree/ThreeDSecure', '6.30.0'
  s.dependency 'Braintree', '6.30.0'
end
