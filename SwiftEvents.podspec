Pod::Spec.new do |s|
  s.name         = 'SwiftEvents'
  s.version      = '0.2.0'
  s.homepage     = 'https://github.com/denissimon/SwiftEvents'
  s.author      = { 'Denis Simon' => 'denis.v.simon@gmail.com' }
  s.summary      = 'A lightweight, pure-Swift library for implementing events in iOS and other platforms'
  s.description      = <<-DESC
  SwiftEvents is a lightweight, pure-Swift library for implementing events. It has Delegation (one subscriber to the event), NotificationCenter (multiple subscribers to the event) and KVO (observing properties using events) functionality in one simple, not verbose and type-safe API.
                       DESC
  s.license      = { :type => 'MIT' }

  s.swift_version = "4.2"
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"
  s.source       =  { :git => 'https://github.com/denissimon/SwiftEvents.git', :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'
  s.frameworks  = "Foundation"
end
