SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

**SwiftEvents** is a lightweight, pure-Swift library for implementing events. It has `Delegation`, `NotificationCenter` and `Key-Value Observing (KVO)` functionality in one simple, **not verbose** and **type-safe API**. 

The purpose of SwiftEvents is to simplify and improve the communication between components in a modern Swift project.

Features:

- [x] Type Safety: the concrete type value is delivered to the subscriber without the need for downcasting

- [x] Thread Safety: you can `addSubscriber`, `trigger`, `removeSubscriber` from any thread without issues

- [x] Memory Safety: automatic preventing retain cycles in order to **always be protected** from memory leaks (and no need to constantly specify `[weak self]` in closures)

- [x] Cancelable subscriptions: automatic removal of subscribers when they are deallocated, so you don't need to explicitly manage this

- [x] One-time and delayed sending notifications

- [x] Ability to observe properties of any class or struct

- [x] Comprehensive unit test coverage

Installation
------------

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", from: "0.4.2")
]
```

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add this line to your `Podfile`:

```ruby
pod 'SwiftEvents', '~> 0.4.2'
```

#### Carthage

To install SwiftEvents using [Carthage](https://github.com/Carthage/Carthage), add this line to your `Cartfile`:

```
github "denissimon/SwiftEvents"
```

#### Manual

Drag `SwiftEvents.swift` anywhere in your project.

Usage
-----

### Delegation functionality

With SwiftEvents, such a `one-to-one` connection can be done in just two steps: 
1. Create an Event for the publisher
2. Subscribe to the Event

```swift
import Foundation
import SwiftEvents

// The publisher
class MyModel {
    
    let didDownloadEvent = Event<UIImage?>()
    
    func downloadImage(for url: URL) {
        download(url: url) { image in
            self.didDownloadEvent.trigger(image)
        }
    }
}
```

```swift
import UIKit

// The subscriber
class MyViewController: UIViewController {

    let model = MyModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.didDownloadEvent.addSubscriber(target: self, handler: { (self, image) in
            if let image = image {
                self.performUIUpdate(image)
            }
        })
    }
    
    func updateImage() {
        model.downloadImage(for: /* image url */)
    }
}
```

You can use the Event with any complex type. As for the example above, it could have been `(UIImage?, Int)`, where `Int` means the HTTP response status code, in order to show a message in case of an error. 

You can also create multiple Events (didDownloadEvent, onHTTPErrorEvent, etc), and trigger only what is needed.

### NotificationCenter functionality

If notifications must be `one-to-many`, or two objects that need to be connected are too far apart, SwiftEvents can be used in three steps:

1. Create an EventService
2. Create Events which will be held by EventService
3. Subscribe to the appropriate Event

```swift
import SwiftEvents

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
        EventService.get.onDataUpdate.addSubscriber(target: self, handler: { (self, data) in
            self.useData(data)
        })
    }
    
    func useData(_ data: String?) {
        print("Controller1 - data: '\(data)'")
    }
}
```

```swift
class Controller2 {
    
    init() {
        EventService.get.onDataUpdate.addSubscriber(target: self, handler: { (self, data) in
            self.useData(data)
        })
    }
    
    func useData(_ data: String?) {
        print("Controller2 - data: '\(data)'")
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
// => Controller1 - data: 'some data'
// => Controller2 - data: 'some data'
```

### KVO functionality

Just two steps again:

1. Replace the `Type` of property to observe with the `Observable<Type>`
2. Subscribe to the `didChanged` Event

```swift
import Foundation
import SwiftEvents

class NoteViewModel: NSObject, UITextViewDelegate {
    
    let model: Note

    var textView: String!
    var infoLabel: Observable<String>!

    init(model: Note) {
        self.model = model
        super.init()
        textView = model.text
        infoLabel = Observable<String>("Last edit: \(model.editDate.formatted())")
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let now = Date()
        infoLabel.value = "Last edit: \(now.formatted())"
        // other code goes here
    }
}
```

```swift
import UIKit

class NoteViewController: UIViewController {
    
    var viewModel = NoteViewModel(model: model)

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = viewModel
        
        textView.text = viewModel.textView
        infoLabel.text = viewModel.infoLabel.value

        viewModel.infoLabel.didChanged.addSubscriber(target: self, handler: { (self, value) in
            self.updateInfoLabel(value)
        })
    }
            
    func updateInfoLabel(_ value: (new: String, old: String)) {
        infoLabel.text = value.new
    }
}
```

In this MVVM example, every time the ViewModel changes the value of `infoLabel`, the View is notified with new and old values, and updates `infoLabel.text`.

You can use the infix operator <<< to set a new value for an observable property:

```swift
infoLabel <<< "Last edit: \(model.editDate.formatted())"
```

### Advanced topics

#### Manual removal of a subscriber

A subscriber can be removed from the Event subscribers manually:

```swift
func startListening() {
    someEvent.addSubscriber(target: self, handler: { (self, result) in
        print(result)
    })
}

func stopListening() {
    someEvent.removeSubscriber(target: self)
}
```

#### Removal of all subscribers

To remove all Event subscribers:

```swift
someEvent.removeAllSubscribers()
```

#### subscribersCount

To get the number of subscribers to the Event:

```swift
let subscribersCount = someEvent.subscribersCount
```

#### triggersCount

To get the number of times the Event has been triggered:

```swift
let triggersCount = someEvent.triggersCount
```

#### Reset of triggersCount

To reset the number of times the Event has been triggered:

```swift
someEvent.resetTriggersCount()
```

#### Optional `queue: DispatchQueue`

By default, a subscriber's handler is executed on the thread that triggers the Event. To change the default behaviour, you can set this parameter when adding a subscriber:

```swift
// This executes the subscriber's handler on the main queue
someEvent.addSubscriber(target: self, queue: .main, handler: { (self, data) in
    self.updateUI(data)
})
```

#### Optional `onetime: Bool`

After a single notification, the subscriber will be automatically removed from the Event subscribers:

```swift
someEvent.addSubscriber(target: self, onetime: true, handler: { (self, data) in
    self.useData(data)
})
```

#### Optional `delay: Double`

For executing the subscriber's handler with a delay (in seconds):

```swift
someEvent.addSubscriber(target: self, delay: 1.0, handler: { (self, data) in
    self.useData(data)
})
```

The default queue for delayed notifications is `global()`. You can set another by specifying an additional parameter `queue`.

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
