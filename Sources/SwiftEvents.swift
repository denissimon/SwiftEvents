//
// SwiftEvents.swift
// https://github.com/denissimon/SwiftEvents
//
// Created by Denis Simon on 05/29/2019
//
// MIT License
//

import Foundation

/// A type-safe Event with built-in security.
final public class Event<T> {
    
    private var subscribers = [EventSubscription<T>]()
    
    public var subscribersCount: Int {
        return subscribers.count
    }
    
    /// The number of times the Event has triggered.
    public private(set) var triggerCount = Int()
    
    public init() {}
    
    /// Adds a new Event subscriber.
    ///
    /// - Parameter target: The target object that subscribes to the Event. If the target object is
    ///   deallocated, it is automatically removed from the Event subscribers.
    /// - Parameter handler: The closure you want executed when the Event triggers.
    public func addSubscriber<O: AnyObject>(target: O, handler: @escaping (O, T) -> ()) {
        let magicHandler: (T) -> () = { [weak target] data in
            if let target = target {
                handler(target, data)
            }
        }
        let wrapper = EventSubscription(target: target, handler: magicHandler)
        subscribers.append(wrapper)
    }
    
    /// Triggers the Event, calls all handlers.
    ///
    /// - Parameter data: The data to trigger the Event with.
    public func trigger(_ data: T) {
        triggerCount += 1
        
        for subscriber in subscribers {
            if subscriber.target != nil {
                subscriber.handler(data)
            } else {
                // Removes the subscriber when it is deallocated.
                removeSubscriber(id: subscriber.id)
            }
        }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter id: The id of the subscriber.
    private func removeSubscriber(id: ObjectIdentifier) {
        subscribers = subscribers.filter { $0.id != id }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter target: The target object that subscribes to the Event.
    public func removeSubscriber(target: AnyObject) {
        removeSubscriber(id: ObjectIdentifier(target))
    }
    
    /// Removes all subscribers on this instance.
    public func removeAllSubscribers() {
        subscribers.removeAll()
    }
}

/// Wrapper that contains information related to a subscription.
fileprivate struct EventSubscription<T> {
    weak var target: AnyObject?
    let handler: (T) -> ()
    let id: ObjectIdentifier
    
    init(target: AnyObject, handler: @escaping (T) -> ()) {
        self.target = target
        self.handler = handler
        self.id = ObjectIdentifier(target)
    }
}

/// KVO functionality
final public class Observable<T> {
    public let didChanged = Event<(T, T)>()
    
    public var value: T {
        didSet {
            didChanged.trigger((value, oldValue))
        }
    }
    
    public init(_ v: T) {
        value = v
    }
}

/// Helper operator to trigger Event data.
infix operator <<<
public func <<< <T> (left: Observable<T>?, right: @autoclosure () -> T) {
    left?.value = right()
}
