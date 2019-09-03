SwiftEvents
===========

**SwiftEvents** is a lightweight, pure-Swift library for implementing events in iOS, macOS, watchOS, tvOS and Linux. It has `NotificationCenter` (multiple listeners to the event), `Delegation` (one listener to the event) and `KVO` (observing properties using the event) functionality in one simple, **not verbose** and **type-safe API**. 

The purpose of SwiftEvents is to simplify and improve the communication between components in a modern Swift project.

In comparison with Cocoa mechanisms, SwiftEvents has the following features:

- [x] Type-safety

- [x] Built-in solution for preventing retain cycles (no need to specify `[weak self]`!), in order to **always be protected** from memory leaks

- [x] Cancelable subscriptions: automatic removal of listeners when they are deallocated, so you don't need to explicitly manage this

- [ ] Thread-safety: listeners can be registered on a different thread than notifications are sent on

- [ ] Delayed and one-time sending notifications

- [ ] Ability to observe properties in any class or any struct

- [ ] Easier to test, maintain and debug

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
