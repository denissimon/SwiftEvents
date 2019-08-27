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
public class Event<T> {
    
    private var listeners = [ListenerWrapper]()
    
    public init() {}
    
    /// Adds a new event listener.
    /// - handler: The closure you want executed when the event triggers.
    func addListener<U: AnyObject>(_ target: U, handler: @escaping (U) -> (T) -> ()) {
        let wrapper = Wrapper(target: target, handler: handler)
        listeners.append(wrapper)
    }
    
    /// Triggers the event, calls all handlers.
    func trigger(data: T) {
        for listener in listeners {
            listener.rise(data: data)
        }
    }
    
    /// Removes all listeners on this instance.
    func removeListeners() {
        self.listeners.removeAll()
    }
}

private protocol ListenerWrapper {
    func rise(data: Any)
    func getId() -> ObjectIdentifier?
}

private struct Wrapper<T: AnyObject, U>: ListenerWrapper {
    weak var target: T?
    let handler: (T) -> (U) -> ()
    
    private var id: ObjectIdentifier?
    
    init(target: T?, handler: @escaping (T) -> (U) -> ()) {
        self.target = target
        self.handler = handler
        if target != nil {
            self.id = ObjectIdentifier(target!)
        }
    }
    
    func rise(data: Any) {
        if let target = target {
            handler(target)(data as! U)
        }
    }
    
    func getId() -> ObjectIdentifier? {
        return id
    }
}
