//
//  EventService.swift
//  SwiftEvents
//
//  Created by Denis Simon on 02/07/2020.
//  Copyright © 2020 SwiftEvents. All rights reserved.
//

import SwiftEvents

public class EventService {
    
    public static let get = EventService()
    
    private init() {}
    
    public let sharedEvent = Event<Int?>()
}

public class Controller1 {
    
    var handledCount = 0
    
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            self?.handledCount += 1
        }
    }
}

public class Controller2 {
    
    var handledCount = 0
    
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            self?.handledCount += 1
        }
    }
}
