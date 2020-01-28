SwiftEvents
===========

[![Swift](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg)](https://developer.apple.com/swift/)

**SwiftEvents** is a lightweight, pure-Swift library for implementing events. It has `Delegation` (one subscriber to the event), `NotificationCenter` (multiple subscribers to the event) and `KVO` (observing properties using events) functionality in one simple, **not verbose** and **type-safe API**. 

The purpose of SwiftEvents is to simplify and improve the communication between components in a modern Swift project.

Features:

- [x] Type Safety: the concrete type value is delivered to the subscriber without the need for downcasting

- [x] Thread Safety: notifications can be sent on a different thread than where subscribers are registered without any data issues

- [x] Memory Safety: a built-in solution for preventing retain cycles to **always be protected** from memory leaks (and no need to constantly specify `[weak self]` in closures)

- [x] Cancelable subscriptions: automatic removal of subscribers when they are deallocated, so you don't need to explicitly manage this

- [x] Delayed and one-time sending notifications

- [x] Ability to observe properties of any class or struct

Installation
------------

#### Swift Package Manager

To install SwiftEvents using the [Swift Package Manager](https://swift.org/package-manager), add it to your `Package.swift` file:

```swift
dependencies: [
    .Package(url: "https://github.com/denissimon/SwiftEvents.git", majorVersion: 0)
]
```

#### CocoaPods

To install SwiftEvents using [CocoaPods](https://cocoapods.org), add it to your `Podfile`:

```ruby
pod 'SwiftEvents'
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

Here is a common scenario: we have a ViewController and a Model that does some work, and we want the ViewController to be notified on the result of this work when it is completed, in order to update the UI.

With SwiftEvents, this can be done in just two steps: 
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

You can use the Event with any complex type. As for the example above, it could have been `(UIImage?, Int)`, where `Int` means the HTTP response status code, to show a message in case of an error. You can also create multiple Events (didDownloadEvent, onHTTPErrorEvent, etc), and trigger only what is needed.

### NotificationCenter functionality

If notifications must be `one-to-many`, or two objects that need to be connected are too far apart (in different components/modules), SwiftEvents can be used in three steps:

1. Create an EventService, which will be holding Events
2. Subscribe to the appropriate Event
3. Trigger the appropriate Event by the publisher

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

Suppose we want to use the MVVM architecture. Observation is one of the methods used for this purpose, and this way the View will be able to react to changes in the ViewModel. Just two steps again:

1. Replace the `Type` of property to observe with the `Observable<Type>`
2. Subscribe to the `didChanged` Event

```swift
import Foundation
import SwiftEvents

class NoteViewModel: NSObject, UITextViewDelegate {
    
    let model: Note // text: String, lastEdit: Date?
    
    var textView: String!
    var infoLabel: Observable<String>!
    
    init(model: Note) {
        self.model = model
        super.init()
        textView = model.text
        infoLabel = Observable<String>("Last edit: \(getFormattedDate())")
    }
    
    // MARK: UITextViewDelegate
    func textViewDidEndEditing(_ textView: UITextView) {
        // the model's data were updated with textView.text and Date()
        textView = model.text
        infoLabel.value = "Last edit: \(getFormattedDate())"
    }
    
    func getFormattedDate() -> String {
        var date = ""
        // the model.lastEdit was formatted and transformed to String
        return date
    }
}

```

```swift
import UIKit

let model = Note()

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

In this example, every time the ViewModel changes the value of `infoLabel`, the View is notified (with the new and old values) and updates `infoLabel.text`.

You can use the infix operator <<< to set a new value for an observable property:

```swift
infoLabel <<< "Last edit: \(getFormattedDate())"
```

### Advanced topics

#### Manual removal of a subscriber

A subscriber can be removed from the Event subscribers manually, before it gets deallocated and removed automatically:

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

To get the count of Event subscribers:

```swift
let subscribersCount = someEvent.subscribersCount
```

#### triggersCount

To get the count of Event triggers:

```swift
let triggersCount = someEvent.triggersCount
```

#### Delayed sending notifications

Set the optional parameter `delay: Double` when adding a subscriber, and its handler will be executed after the specified delay (in seconds):

```swift
someEvent.addSubscriber(target: self, delay: 1.0, handler: { (self, data) in
    self.useData(data)
})
```

#### One-time sending notifications

Set the optional parameter `onetime: true` when adding a subscriber, and after a single notification it will be automatically removed from the Event subscribers:

```swift
someEvent.addSubscriber(target: self, onetime: true, handler: { (self, data) in
    self.useData(data)
})
```

The optional parameters of `addSubscriber()` can be set together in any combination.

License
-------

Licensed under the [MIT license](https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
