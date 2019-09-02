SwiftEvents
===========

**SwiftEvents** is a lightweight, pure-Swift library for implementing events in iOS, macOS, watchOS, tvOS and Linux. It has `NotificationCenter`, `Delegation` and `KVO` functionality in one simple, **not verbose** and **type-safe API**. In particular, MVVM is one of the bright examples when SwiftEvents can be the easiest and fastest way for the View to react to changes in the ViewModel. 

Along with this, the library has a built-in solution for preventing retain cycles (no need to specify `[weak self]`!), in order to be **always secure** from memory leaks. It also automatically removes listeners when they are deallocated, so you don't need to explicitly manage this.

In comparison with Cocoa mechanisms, SwiftEvents as well:

* Uses native Swift syntax: closures, generics and didSet property observers

* Provides the ability to observe properties in any class or any struct

* Provides the ability to observe all of the properties of an instance without significant efforts

* Easier to test, maintain and debug. And much more.

Installation
------------

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add it to your `Podfile`:

```ruby
pod 'SwiftEvents'
```

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", majorVersion: 0)
]
```

#### Manual

Drag the `Sources` folder anywhere in your project.

Usage
-----

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
