SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

SwiftEvents is a lightweight library for creating and observing events.

It includes:
* `Observable<T>` - a type-safe class for data binding that can be particularly used in MVVM.
* `Event<T>` - a type-safe class for any notifications, including one-to-many with multiple subsribers.

SwiftEvents has a thread-safe version - `EventTS<T>` and `ObservableTS<T>` classes. This way, its properties and methods can be safely accessed by multiple threads at the same time.

Another important feature is the automatic unsubscription of subscribers/observers when they are deallocated.

Comprehensive [unit test](https://github.com/denissimon/SwiftEvents/blob/master/Tests/SwiftEventsTests) coverage.

Installation
------------

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager):

```txt
Xcode: File -> Add Packages
Enter Package URL: https://github.com/denissimon/SwiftEvents
```

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'SwiftEvents', '~> 2.1'
```

#### Carthage

To install SwiftEvents using [Carthage](https://github.com/Carthage/Carthage), add this line to your `Cartfile`:

```ruby
github "denissimon/SwiftEvents"
```

#### Manually

Copy `SwiftEvents.swift` into your project.

Usage
-----

### Observable

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
        viewModel.infoLabel.bind(self) { [weak self] in self?.updateInfoLabel($0) }
    }

    private func updateItems() { ... }

    private func updateInfoLabel(_ newText: String) {
        infoLabel.text = newText
    }
}
```

In this example, every time the ViewModel changes the value of the observable property `items` or `infoLabel`, the View is notified and updates its UI.

The infix operator <<< can be used to set a new value for an observable property:

```swift
items.value = newData
items <<< newData
```

### Event

Example implementation of the closure-based delegation pattern:

```swift
class MyModel {
    
    let didDownload = Event<UIImage?>()
    
    func downloadImage(for url: URL) {
        service.download(url: url) { [weak self] image in
            self?.didDownload.notify(image)
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

Event and Observable conform to `Unsubscribable` and `Unbindable` protocols respectively, which allows to pass a reference to an object that should only call `unsubscribe` / `unbind`.

### More examples

More usage examples can be found in [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture).

Also [tests](https://github.com/denissimon/SwiftEvents/blob/master/Tests/SwiftEventsTests/EventService.swift) contains a NotificationCenter-like implementation, and here is a [gist](https://gist.github.com/denissimon/3b8c5a02ad2ce5f290f3fbecdbfb2fda) with a cell-to-cellViewModel binding example.

### Advanced features

#### Removal of a subscriber / observer

Deallocated subscribers/observers are automatically removed from Event/Observable. But they also can be removed manually:

```swift
someEvent.subscribe(self) { [weak self] in self?.setValue($0) }
someEvent.unsubscribe(self)

someObservable.bind(cell) { [weak cell] in cell?.update($0) }
someObservable.unbind(cell)
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

By default, the provided handler is executed on the thread that triggers the Event/Observable. To change this default behaviour:

```swift
// This executes the handler on the main thread
someEvent.subscribe(self, queue: .main) { [weak self] in self?.updateTable($0) }
someObservable.bind(self, queue: .main) { [weak self] in self?.updateTable($0) }
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
