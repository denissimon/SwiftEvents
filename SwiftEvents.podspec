Pod::Spec.new do |s|
  s.name         = 'SwiftEvents'
  s.version      = '2.0.1'
  s.homepage     = 'https://github.com/denissimon/SwiftEvents'
  s.authors      = { 'Denis Simon' => 'denis.v.simon@gmail.com' }
  s.summary      = 'A thread-safe library for data binding and notifications based on events. Includes Event<T> and Observable<T>.'
  s.license      = { :type => 'MIT' }

  s.swift_versions = ['5']
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"
  s.source       =  { :git => 'https://github.com/denissimon/SwiftEvents.git', :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'
  s.frameworks  = "Foundation"
end
