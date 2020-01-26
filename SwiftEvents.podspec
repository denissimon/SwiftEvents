Pod::Spec.new do |s|
  s.name         = 'SwiftEvents'
  s.version      = '0.1.1'
  s.homepage     = 'https://github.com/denissimon/SwiftEvents'
  s.authors      = {
    'Denis Simon' => 'denis.v.simon@gmail.com'
  }
  s.summary      = 'A lightweight, pure-Swift library for implementing events in iOS and other platforms.'
  s.description      = <<-DESC
  SwiftEvents is a lightweight, pure-Swift library for implementing events in iOS, macOS, watchOS, tvOS and Linux. It has NotificationCenter (multiple subscribers to the event), Delegation (one subscriber to the event) and KVO (observing properties using events) functionality in one simple, not verbose and type-safe API. Features: Type Safety, Thread Safety, Memory Safety, Cancelable subscriptions, and others.
                       DESC
  s.license      = { :type => 'MIT' }

  s.source       =  {
    :git => 'https://github.com/denissimon/SwiftEvents.git',
    :tag => s.version.to_s
  }
  s.source_files = 'Sources/**/*.swift'

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"
end
