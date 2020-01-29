//
// SwiftEvents.swift
// https://github.com/denissimon/SwiftEvents
//
// Created by Denis Simon on 05/29/2019.
// Copyright © 2019 SwiftEvents. All rights reserved.
//

import Foundation

/// A type-safe Event with built-in security.
final public class Event<T> {
    
    private var subscribers = [EventSubscription<T>]()
    
    /// The number of subscribers to the Event.
    public var subscribersCount: Int {
        return subscribers.count
    }
    
    /// The number of times the Event has been triggered.
    public private(set) var triggersCount = Int()
    
    /// The number of times the handlers of the Event subscribers have been executed.
    public private(set) var handledCount = Int()
    
    private let lock: NSRecursiveLock = .init()
    
    public init() {}
    
    /// Adds a new Event subscriber.
    ///
    /// - Parameter target: The target object that subscribes to the Event. If the target object is
    ///   deallocated, it is automatically removed from the Event subscribers.
    /// - Parameter queue: The queue (and optionally qos) in which the handler should be executed
    ///   when the Event triggers.
    /// - Parameter delay: Whether the handler should be executed with the specified delay.
    /// - Parameter onetime: Whether the handler should be executed onetime and then removed from the
    ///   Event subscribers.
    /// - Parameter handler: The closure you want executed when the Event triggers.
    public func addSubscriber<O: AnyObject>(
        target: O,
        queue: DispatchQueue = .main,
        delay: Double = 0.0,
        onetime: Bool = false,
        handler: @escaping (O, T) -> ()) {
        
        let magicHandler: (T) -> () = { [weak target] data in
            if let target = target {
                handler(target, data)
            }
        }
        
        let wrapper = EventSubscription(
            target: target,
            queue: queue,
            delay: delay,
            onetime: onetime,
            handler: magicHandler
        )
        
        self.lock.with {
            self.subscribers.append(wrapper)
        }
    }
    
    /// Triggers the Event, calls all handlers.
    ///
    /// - Parameter data: The data to trigger the Event with.
    public func trigger(_ data: T) {
        triggersCount += 1
        
        for subscriber in subscribers {
            if subscriber.target != nil {
                
                callHandler(
                    on: subscriber.queue,
                    delay: subscriber.delay,
                    data: data,
                    handler: subscriber.handler
                )
                
                if subscriber.onetime {
                    removeSubscriber(id: subscriber.id)
                }
                
            } else {
                // Removes the subscriber when it is deallocated.
                removeSubscriber(id: subscriber.id)
            }
        }
    }
    
    /// Executes the handler with the provided data and parameters.
    private func callHandler(on queue: DispatchQueue, delay: Double, data: T, handler: @escaping (T) -> ()) {
        self.lock.with {
            if queue == .main {
                if delay == 0 {
                    DispatchQueue.main.async { handler(data) }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { handler(data) }
                }
            } else {
                let global = [
                    "com.apple.root.default-qos",
                    "com.apple.root.background-qos",
                    "com.apple.root.user-initiated-qos",
                    "com.apple.root.user-interactive-qos",
                    "com.apple.root.utility-qos"
                ]
                if global.contains(queue.label) {
                    if delay == 0 {
                        DispatchQueue.global(qos: queue.qos.qosClass).async { handler(data) }
                    } else {
                        DispatchQueue.global(qos: queue.qos.qosClass)
                            .asyncAfter(deadline: .now() + delay) { handler(data) }
                    }
                } else {
                    if delay == 0 {
                        DispatchQueue.init(label: queue.label).async { handler(data) }
                    } else {
                        DispatchQueue.init(label: queue.label)
                            .asyncAfter(deadline: .now() + delay) { handler(data) }
                    }
                }
            }
            
            self.handledCount += 1
        }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter id: The id of the subscriber.
    private func removeSubscriber(id: ObjectIdentifier) {
        self.lock.with {
            self.subscribers = self.subscribers.filter { $0.id != id }
        }
    }
    
    /// Removes a specific subscriber from the Event subscribers.
    ///
    /// - Parameter target: The target object that subscribes to the Event.
    public func removeSubscriber(target: AnyObject) {
        removeSubscriber(id: ObjectIdentifier(target))
    }
    
    /// Removes all subscribers on this instance.
    public func removeAllSubscribers() {
        self.lock.with {
            self.subscribers.removeAll()
        }
    }
}

/// Wrapper that contains information related to a subscription.
fileprivate struct EventSubscription<T> {
    weak var target: AnyObject?
    let queue: DispatchQueue
    let delay: Double
    let onetime: Bool
    let handler: (T) -> ()
    let id: ObjectIdentifier
    
    init(target: AnyObject, queue: DispatchQueue, delay: Double, onetime: Bool, handler: @escaping (T) -> ()) {
        self.target = target
        self.queue = queue
        self.delay = delay
        self.onetime = onetime
        self.handler = handler
        id = ObjectIdentifier(target)
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
