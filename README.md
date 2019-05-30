SwiftEvents
===========

SwiftEvents is a lightweight, pure-Swift alternative to Cocoa KVO and NotificationCenter.

One of the bright examples of using SwiftEvents is MVVM, as it provides an easier way for the View to react to changes in the ViewModel.

In comparison with Cocoa mechanisms, SwiftEvents:

* Uses native Swift syntax: closures, generics and didSet property observers

* Provides the ability to observe properties in a class or a struct

* Provides the ability to observe all of the properties of an instance with minimal effort

* Easier to test, maintain and debug

Installation
------------

#### Swift Package Manager

To install the library using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", majorVersion: 0)
]
```

#### Manual

If you prefer not to use dependency managers, you can integrate SwiftEvents into your project manually.

Usage
-----

This section is under development.

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
