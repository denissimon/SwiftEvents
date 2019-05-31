Pod::Spec.new do |s|
  s.name         = 'SwiftEvents'
  s.version      = '0.1.1'
  s.homepage     = 'https://github.com/denissimon/SwiftEvents'
  s.authors      = {
    'Denis Simon' => 'denis.v.simon@gmail.com'
  }
  s.summary      = 'A lightweight, pure-Swift alternative to Cocoa KVO and NotificationCenter.'
  s.description      = <<-DESC
  A lightweight, pure-Swift alternative to Cocoa KVO and NotificationCenter. One of the bright examples of using SwiftEvents is MVVM, as it provides an easier way for the View to react to changes in the ViewModel.
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
