Pod::Spec.new do |s|
  s.name             = 'Engage'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Engage.'
  s.homepage         = 'https://engage.so/'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Engage' => 'hello@engage.so' }
  s.source           = { :git => 'https://github.com/engage-so/engage-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/Engage/**/*'
end
