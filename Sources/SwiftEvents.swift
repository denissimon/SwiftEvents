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
    
    private var listeners = [EventSubscription<T>]()
    
    /// The number of times the Event has triggered.
    public private(set) var triggerCount = Int()
    
    public init() {}
    
    /// Adds a new Event listener.
    ///
    /// - Parameter target: The target object that listens to the Event. If the target object is
    ///   deallocated, it is automatically removed from the Event listeners.
    /// - Parameter handler: The closure you want executed when the Event triggers.
    public func addListener<O: AnyObject>(target: O, handler: @escaping (O, T) -> ()) {
        let magicHandler: (T) -> () = { [weak target] data in
            if let target = target {
                handler(target, data)
            }
        }
        let wrapper = EventSubscription(target: target, handler: magicHandler)
        listeners.append(wrapper)
    }
    
    /// Triggers the Event, calls all handlers.
    ///
    /// - Parameter data: The data to trigger the Event with.
    public func trigger(data: T) {
        triggerCount += 1
        
        for listener in listeners {
            if listener.target != nil {
                listener.handler(data)
            } else {
                // Removes the listener when it is deallocated.
                removeListener(id: listener.id)
            }
        }
    }
    
    /// Removes a specific listener from the Event listeners.
    ///
    /// - Parameter id: The id of the listener.
    private func removeListener(id: ObjectIdentifier) {
        listeners = listeners.filter { $0.id != id }
    }
    
    /// Removes a specific listener from the Event listeners.
    ///
    /// - Parameter target: The target object that listens to the Event.
    public func removeListener(target: AnyObject) {
        removeListener(id: ObjectIdentifier(target))
    }
    
    /// Removes all listeners on this instance.
    public func removeAllListeners() {
        listeners.removeAll()
    }
}

/// Wrapper that contains information related to a subscription.
fileprivate struct EventSubscription<T> {
    weak var target: AnyObject?
    var handler: (T) -> ()
    var id: ObjectIdentifier
    
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
            didChanged.trigger(data: (value, oldValue))
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
