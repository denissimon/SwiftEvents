SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

SwiftEvents is a lightweight library for creating and observing events.

It includes:
* `Observable<T>` - a type-safe class for data binding that can be particularly used in MVVM.
* `Event<T>` - a type-safe class for any notifications, including with multiple subscribers.

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
pod 'SwiftEvents', '~> 2.2'
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
    let items: Observable<[Item]> = Observable([])
    let infoLabel: Observable<String> = Observable("")
    ...
}
```

```swift
class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoLabel: UILabel!

    private var viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    private func bind() {
        viewModel.items.bind(self) { [weak self] _ in self?.refreshTable() }
        viewModel.infoLabel.bind(self) { [weak self] in self?.updateInfoLabel($0) }
    }

    private func refreshTable() { ... }

    private func updateInfoLabel(_ text: String) {
        infoLabel.text = text
    }
}
```

In this example, every time the ViewModel changes the value of the observable property `items` or `infoLabel`, the ViewController is notified and updates its UI.

The `<<<` infix operator can be used to set a new value for an observable property:

```swift
items.value = newItems
items <<< newItems
```

### Event

Example implementation of the closure-based delegation pattern:

```swift
class ImageProcessingService {
    
    let didProcess = Event<Image?>()
    
    func processImage(_ image: Image) {
        /* time-consuming processing code */
        didProcess.notify(newImage)
    }
}
```

```swift
class ViewModel {

    private let imageProcessingService: ImageProcessingService
    var image: Image?

    init(imageProcessingService: ImageProcessingService) {
        self.imageProcessingService = imageProcessingService        
        imageProcessingService.didProcess.subscribe(self) { [weak self] image in self?.updateImage(image) }
    }
    
    private func updateImage(_ image: Image?) {
        self.image = image
    }
}
```

You can also create several events (didProcess, didDownload, onNetworkError etc.) and trigger only what is needed.

The Event and Observable classes conform to `Unsubscribable` and `Unbindable` protocols respectively, which allows to pass a reference to an object that should only call `unsubscribe` / `unbind`.

### More examples

More usage examples can be found in [iOS-MVVM-Clean-Architecture](https://github.com/denissimon/iOS-MVVM-Clean-Architecture). Also [tests](https://github.com/denissimon/SwiftEvents/blob/master/Tests/SwiftEventsTests) contain additional examples including a NotificationCenter-like implementation where a shared event and multiple subscribers are used.

### Advanced features

#### Removing a subscriber / observer

Deallocated subscribers/observers are automatically removed from the Event/Observable, but they can also be removed manually:

```swift
someEvent.subscribe(self) { [weak self] in self?.setValue($0) }
someEvent.unsubscribe(self)

someObservable.bind(cell) { [weak cell] in cell?.update($0) }
someObservable.unbind(cell)
```

#### Removing all subscribers / observers

```swift
someEvent.unsubscribeAll()
someObservable.unbindAll()
```

#### Number of subscribers / observers

```swift
someEvent.subscribersCount
someObservable.observersCount
```

#### Number of triggers

```swift
someEvent.triggersCount
someObservable.triggersCount
```

#### queue: DispatchQueue

By default, a provided handler is executed on the thread that triggers the Event/Observable. To change this default behaviour:

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

#### N-time notification

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
