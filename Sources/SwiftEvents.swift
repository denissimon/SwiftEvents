//
// SwiftEvents.swift
//
// SwiftEvents - A lightweight, pure-Swift alternative to Cocoa KVO and NotificationCenter.
//
// Copyright (c) 2019 Denis Simon <denis.v.simon@gmail.com>
//
// Licensed under MIT (https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
//

import Foundation

/// A type-safe EventManager
public class EventManager<T> {
    
    private var listeners = [(T) -> ()]()
    
    public init() {}
    
    /// Adds a new event listener
    /// - action: The closure you want executed when the event triggers
    func addListener(handler: @escaping (T) -> ()) {
        listeners.append(handler)
    }
    
    // Triggers the event, calls all handlers
    func trigger(data: T) {
        for handlerToCall in listeners {
            handlerToCall(data)
        }
    }
    
    // Removes all listeners on this instance
    func removeListeners() {
        self.listeners = []
    }
}
