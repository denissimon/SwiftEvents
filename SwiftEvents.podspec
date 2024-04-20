Pod::Spec.new do |s|
  s.name         = 'SwiftEvents'
  s.version      = '2.1.2'
  s.homepage     = 'https://github.com/denissimon/SwiftEvents'
  s.authors      = { 'Denis Simon' => 'denis.v.simon@gmail.com' }
  s.summary      = 'The easiest way to implement data binding and notifications. Includes Event<T> and Observable<T>. Has a thread-safe version.'
  s.license      = { :type => 'MIT' }

  s.swift_versions = ['5']
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "12.0"
  s.source       =  { :git => 'https://github.com/denissimon/SwiftEvents.git', :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'
  s.frameworks  = "Foundation"
end
