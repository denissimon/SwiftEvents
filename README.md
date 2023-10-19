SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

SwiftEvents is a lightweight library for creating and observing events.

It includes:
* `Observable<T>` for data binding that can be used in MVVM. Observable is implemented using Event class.
* `Event<T>` for closure based delegation and one-to-many notifications.

Features:

- [x] Type safety: the concrete type value is delivered to the subscriber without the need for downcasting

- [x] Thread safety: you can `subscribe` / `bind`, `trigger`, `unsubscribe` / `unbind` from any thread without issues such as data races

- [x] Memory safety: automatic preventing retain cycles, without strictly having to specify `[weak self]` in closure when subscribing/binding. Whether you specified `[weak self]` or not, it’s sometimes forgotten to specify - safety against memory leaks will be ensured automatically. As well as automatic removal of subscribers/observers when they are deallocated

- [x] Comprehensive unit test coverage

Installation
------------

#### Manual

Copy `SwiftEvents.swift` into your project.

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'SwiftEvents', '~> 1.1.1'
```

#### Carthage

To install SwiftEvents using [Carthage](https://github.com/Carthage/Carthage), add this line to your `Cartfile`:

```
github "denissimon/SwiftEvents"
```

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", from: "1.1.1")
]
```

Usage
-----

### Data binding

1. Replace the `Type` of property to observe with the `Observable<Type>`
2. Bind to the Observable

Example:

```swift
class ViewModel {
    
    var infoLabel: Observable<String> = Observable("init value")

    func set(newValue: String) {
        infoLabel.value = newValue
    }
}
```

```swift
class View: UIViewController {
    
    var viewModel = ViewModel()

    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = viewModel.infoLabel.value
        
        viewModel.infoLabel.bind(self) { (self, value) in self.updateInfoLabel(value) }
    }

    private func updateInfoLabel(_ value: String) {
        infoLabel.text = value
    }
}
```

Note: here a capture list is intentionally not specified in closure before `(self, value)` because under the hood SwiftEvents will construct a new closure with `[weak target]` included there. This way a strong reference cycle will be avoided.

In the above example, every time ViewModel changes the value of the observable property `infoLabel`, View is notified and updates the `infoLabel.text`.

You can use the infix operator <<< to set a new value for an observable property:

```swift
infoLabel <<< newValue
```

An Observable can have multiple observers, and when the property's value is updated, all of them will be notified.

### Delegation

Delegation can be implemented not only using protocols, but also based on closure. Such a one-to-one connection can be done in two steps:

1. Create an Event for the publisher
2. Subscribe to the Event

Example:

```swift
class MyModel {
    
    let didDownload = Event<UIImage?>()
    
    func downloadImage(for url: URL) {
        service.download(url: url) { [weak self] image in
            self?.didDownload.trigger(image)
        }
    }
}
```

```swift
class MyViewController: UIViewController {

    let model = MyModel()
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.didDownload.subscribe(self) { (self, image) in self.updateImage(image) }
    }
    
    private func updateImage(_ image: UIImage?) {
        self.image = image
    }
}
```

You can use Event with any complex type, including custom types and multiple values like `(UIImage, Int)?`. You can also create several events (didDownload, onNetworkError etc), and trigger only what is needed.

### Notifications

If notifications must be one-to-many, or two objects that need to be connected are too far apart, SwiftEvents can be used like NotificationCenter:

Example:

```swift
public class EventService {
    
    public static let get = EventService()
    
    private init() {}
    
    // Events
    public let onDataUpdate = Event<String?>()
}
```

```swift
class Controller1 {    
    init() {
        EventService.get.onDataUpdate.subscribe(self) { (self, data) in
            print("Controller1: '\(data)'")
        }
    }
}
```

```swift
class Controller2 {
    init() {
        EventService.get.onDataUpdate.subscribe(self) { (self, data) in
            print("Controller2: '\(data)'")
        }
    }
}
```

```swift
class DataModel {
    
    private(set) var data: String? {
        didSet {
            EventService.get.onDataUpdate.trigger(data)
        }
    }
    
    func requestData() {
        // requesting code goes here
        data = "some data"
    }
}
```

```swift
let sub1 = Controller1()
let sub2 = Controller2()
let pub = DataModel()
pub.requestData()
// => Controller1: 'some data'
// => Controller2: 'some data'
```

### Other examples

More examples of using SwiftEvents can be found in [SwiftEventsTests.swift](https://github.com/denissimon/SwiftEvents/blob/master/Tests/SwiftEventsTests/SwiftEventsTests.swift) and in this [demo app](https://github.com/denissimon/ImageSearch).

### Advanced features

#### Manual removal of a subscriber / observer

```swift
someEvent.subscribe(self) { (self, value) in self.setValue(value) }
someEvent.unsubscribe(self)

someObservable.bind(self) { (self, value) in self.setValue(value) }
someObservable.unbind(self)
```

#### Removal of all subscribers / observers

```swift
someEvent.unsubscribeAll()
someObservable.unbindAll()
```

#### The number of subscribers to the Event

```swift
let subscribersCount = someEvent.subscribersCount
```

#### The number of times the Event was triggered

```swift
let triggersCount = someEvent.triggersCount
```

#### Reset of triggersCount

```swift
someEvent.resetTriggersCount()
```

#### queue: DispatchQueue

By default, the provided handler is executed on the thread that triggers the Event / Observable. To change this default behaviour, you can set this parameter when subscribing/binding:

```swift
// This executes the handler on the main queue
someEvent.subscribe(self, queue: .main) { (self, image) in self.updateImage(image) }
someObservable.bind(self, queue: .main) { (self, image) in self.updateImage(image) }
```

#### One-time notification

To make the handler execute only once:

```swift
someObservable.bind(self) { (self, data) in
    self.useData(data)
    self.someObservable.unbind(self)
}
```

#### N-time notifications

To make the handler execute N times:

```swift
let n = 5
someEvent.subscribe(self) { (self, data) in
    self.useData(data)
    if self.someEvent.triggersCount == n {
        self.someEvent.unsubscribe(self)
    }
}
```

#### Alias methods 

There are alias methods for Event `addSubscriber`, `removeSubscriber` and `removeAllSubscribers`, which do the same thing as `subscribe`, `unsubscribe` and `unsubscribeAll` respectively.

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
