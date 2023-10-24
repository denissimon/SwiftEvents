SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

SwiftEvents is a lightweight library for creating and observing events.

It includes:
* `Observable<T>` for data binding that can be particularly used in MVVM. Observable is implemented using the Event class.
* `Event<T>` for any notifications, including one-to-many, closure-based delegation, NotificationCenter-like implementation, etc.

SwiftEvents is thread-safe, so its properties and methods, e.g. `subscribe` / `bind`, `trigger`, `unsubscribe` / `unbind`, can be safely called by multiple threads at the same time.

Comprehensive [unit test](https://github.com/denissimon/SwiftEvents/blob/master/Tests/SwiftEventsTests/SwiftEventsTests.swift) coverage.

Installation
------------

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'SwiftEvents', '~> 1.3.0'
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
    .package(url: "https://github.com/denissimon/SwiftEvents.git", from: "1.3.0")
]
```

#### Manually

Just drag `SwiftEvents.swift` to the project tree.

Usage
-----

### Data binding

Example:

```swift
class ViewModel {
    let items: Observable<[SomeItem]> = Observable([])
    let infoLabel: Observable<String> = Observable("")
}
```

```swift
class View: UIViewController {
    
    var viewModel = ViewModel()

    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    private func bind() {
        viewModel.items.bind(self) { [weak self] _ in self?.updateItems() }
        viewModel.infoLabel.bind(self) { [weak self] value in self?.updateInfoLabel(value) }
    }

    private func updateItems() {
        refreshUI()
    }

    private func updateInfoLabel(_ value: String) {
        infoLabel.text = value
    }
}
```

In this example, every time the ViewModel changes the value of the observable property `items` or `infoLabel`, the View is notified and updates its UI.

As with Event, you can use Observable with any complex type, including custom types, such as `Observable<LoginResult?>`, and multiple values such as `Observable<(UIImage, Int)>`. As with Event, an Observable can have multiple observers.

The infix operator <<< can be used to set a new value for an observable property:

```swift
infoLabel <<< newValue
```

### Notifications

Using `Event<T>`, any one-to-one or one-to-many notifications can be implemented. Here is, for example, an implementation of closure-based delegation pattern:

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
        model.didDownload.subscribe(self) { [weak self] image in self?.updateImage(image) }
    }
    
    private func updateImage(_ image: UIImage?) {
        self.image = image
    }
}
```

You can also create several events (didDownload, onNetworkError etc), and trigger only what is needed.

### NotificationCenter-like

If notifications must be one-to-many, or two objects that need to be connected are too far apart, SwiftEvents can be used like NotificationCenter.

Example:

```swift
public class EventService {
    
    public static let get = EventService()
    
    private init() {}
    
    public let onDataUpdate = Event<String?>()
}
```

```swift
class Controller1 {    
    init() {
        EventService.get.onDataUpdate.subscribe(self) { _ in
            print("Controller1: '\(data)'")
        }
    }
}
```

```swift
class Controller2 {
    init() {
        EventService.get.onDataUpdate.subscribe(self) { _ in
            print("Controller2: '\(data)'")
        }
    }
}
```

```swift
class DataModel {
    func requestData() {
        // requesting code goes here
        data = "some data"
        EventService.get.onDataUpdate.trigger(data)
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

### More examples

More usage examples can be found in this [demo app](https://github.com/denissimon/ImageSearch).

### Advanced features

#### Manual removal of a subscriber / observer

```swift
someEvent.subscribe(self) { [weak self] in self?.setValue($0) }
someEvent.unsubscribe(self)

someObservable.bind(self) { [weak self] in self.setValue($0) }
someObservable.unbind(self)
```

#### Removal of all subscribers / observers

```swift
someEvent.unsubscribeAll()
someObservable.unbindAll()
```

#### The number of subscribers / observers

```swift
someEvent.subscribersCount
someObservable.observersCount
```

#### The number of triggers

```swift
someEvent.triggersCount
someObservable.triggersCount
```

#### queue: DispatchQueue

By default, the provided handler is executed on the thread that triggers the Event / Observable. To change this default behaviour, you can set this parameter when subscribing/binding:

```swift
// This executes the handler on the main queue
someEvent.subscribe(self, queue: .main) { [weak self] in self?.updateImage($0) }
someObservable.bind(self, queue: .main) { [weak self] in self?.updateImage($0) }
```

#### One-time notification

To ensure that the handler will be executed only once:

```swift
someEvent.subscribe(self) { [weak self] data in
    guard let self = self else { return }
    self.useData(data)
    self.someEvent.unsubscribe(self)
}
```

#### N-time notifications

To ensure that the handler will be executed no more than `n` times:

```swift
someEvent.subscribe(self) { [weak self] data in
    guard let self = self else { return }
    self.useData(data)
    if self.someEvent.triggersCount >= n { self.someEvent.unsubscribe(self) }
}
```

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
