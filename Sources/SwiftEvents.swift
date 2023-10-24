//
//  SwiftEvents.swift
//  https://github.com/denissimon/SwiftEvents
//
//  Created by Denis Simon on 05/29/2019.
//  Copyright © 2019 SwiftEvents. All rights reserved.
//

import Foundation
#if os(Linux)
import Dispatch
#endif

final public class Event<T> {
    
    fileprivate struct Subscriber<T>: Identifiable {
        weak var target: AnyObject?
        let queue: DispatchQueue?
        let handler: (T) -> ()
        let id: ObjectIdentifier
        
        init(target: AnyObject, queue: DispatchQueue?, handler: @escaping (T) -> ()) {
            self.target = target
            self.queue = queue
            self.handler = handler
            id = ObjectIdentifier(target)
        }
    }
    
    private var subscribers = [Subscriber<T>]()
    
    private let notificationQueue = DispatchQueue(label: "com.swift.events.dispatch.queue", attributes: .concurrent)
    
    /// The number of subscribers to the Event
    public var subscribersCount: Int {
        return getSubscribers().count
    }
    
    private var _triggersCount = Int()
    
    /// The number of times the Event was triggered
    public var triggersCount: Int {
        return getTriggersCount()
    }
    
    public init() {}
    
    /// Subscribes to the Event
    ///
    /// - Parameter target: The target object that subscribes to the Event
    /// - Parameter queue: The queue in which the handler should be executed when the Event triggers
    /// - Parameter handler: The closure you want executed when the Event triggers
    public func subscribe<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (O, T) -> ()) {
        
        let constructedClosure: (T) -> () = { [weak target] data in
            if let target = target {
                handler(target, data)
            }
        }
        
        let wrapper = Subscriber(target: target, queue: queue, handler: constructedClosure)
        
        notificationQueue.async(flags: .barrier) {
            self.subscribers.append(wrapper)
        }
    }
    
    /// Alias for 'subscribe'
    public func addSubscriber<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (O, T) -> ()) {
        subscribe(target, queue: queue, handler: handler)
    }
    
    /// Triggers the Event, calls all handlers
    ///
    /// - Parameter data: The data to trigger the Event with
    public func trigger(_ data: T) {
        notificationQueue.async(flags: .barrier) {
            self._triggersCount += 1
        }
        
        let subscribers = getSubscribers()
        
        for subscriber in subscribers {
            if subscriber.target != nil {
                callHandler(on: subscriber.queue, data: data, handler: subscriber.handler)
            } else {
                // Removes the subscriber if it is deallocated
                unsubscribe(id: subscriber.id)
            }
        }
    }
    
    /// Executes the handler with provided data
    private func callHandler(on queue: DispatchQueue?, data: T, handler: @escaping (T) -> ()) {
        guard let queue = queue else {
            handler(data)
            return
        }
        queue.async {
            handler(data)
        }
    }
    
    /// Unsubscribes from the Event
    ///
    /// - Parameter id: The id of the subscriber
    private func unsubscribe(id: ObjectIdentifier) {
        notificationQueue.async(flags: .barrier) {
            self.subscribers = self.subscribers.filter { $0.id != id }
        }
    }
    
    /// Unsubscribes from the Event
    ///
    /// - Parameter target: The target object that subscribes to the Event
    public func unsubscribe(_ target: AnyObject) {
        unsubscribe(id: ObjectIdentifier(target))
    }
    
    /// Alias for 'unsubscribe'
    public func removeSubscriber(_ target: AnyObject) {
        unsubscribe(target)
    }
    
    /// Unsubscribes all subscribers from the Event
    public func unsubscribeAll() {
        notificationQueue.async(flags: .barrier) {
            self.subscribers.removeAll()
        }
    }
    
    /// Alias for 'unsubscribeAll'
    public func removeAllSubscribers() {
        unsubscribeAll()
    }
    
    /// Resets the number of times the Event was triggered
    public func resetTriggersCount() {
        notificationQueue.async(flags: .barrier) {
            self._triggersCount = 0
        }
    }
    
    private func getSubscribers() -> [Subscriber<T>] {
        var result = [Subscriber<T>]()
        notificationQueue.sync {
            result = subscribers
        }
        return result
    }
    
    private func getTriggersCount() -> Int {
        var result = Int()
        notificationQueue.sync {
            result = _triggersCount
        }
        return result
    }
}

final public class Observable<T> {
    
    private let didChanged = Event<T>()
    
    public var value: T {
        didSet {
            didChanged.trigger(value)
        }
    }
    
    public init(_ v: T) {
        value = v
    }
    
    /// Binds to the Observable
    ///
    /// - Parameter target: The target object that binds to the Observable
    /// - Parameter queue: The queue in which the handler should be executed when the Observable's value changes
    /// - Parameter handler: The closure you want executed when the Observable's value changes
    public func bind<O: AnyObject>(_ target: O, queue: DispatchQueue? = nil, handler: @escaping (O, T) -> ()) {
        didChanged.addSubscriber(target, queue: queue, handler: handler)
    }
    
    /// Unbinds from the Observable
    ///
    /// - Parameter target: The target object that binds to the Observable
    public func unbind(_ target: AnyObject) {
        didChanged.removeSubscriber(target)
    }
    
    /// Unbinds all observers from the Observable
    public func unbindAll() {
        didChanged.removeAllSubscribers()
    }
}

/// Helper operator to set a new value for an Observable
infix operator <<<
public func <<< <T> (left: Observable<T>, right: @autoclosure () -> T) {
    left.value = right()
}
