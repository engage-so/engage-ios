Pod::Spec.new do |s|
  s.name             = 'engage-ios'
  s.version          = '0.1.0'
  s.module_name      = 'Engage'
  s.summary          = 'Official Engage SDK for iOS.'
  s.homepage         = 'https://engage.so/'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Engage, Inc' => 'hello@engage.so' }
  s.source           = { :git => 'https://github.com/engage-so/engage-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.cocoapods_version = '>= 1.11.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/**/*.swift'
end
