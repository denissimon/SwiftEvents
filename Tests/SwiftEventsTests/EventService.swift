//
//  EventService.swift
//  https://github.com/denissimon/SwiftEvents
//
//  Created by Denis Simon on 02/07/2020.
//  Copyright © 2020 SwiftEvents. All rights reserved.
//

import SwiftEvents

public class EventService {
    
    public static let get = EventService()
    
    private init() {}
    
    public let sharedEvent = Event<Int?>()
    public let sharedEventTS = EventTS<Int?>()
}

public class Controller1 {
    var callsCount = 0
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
        }
    }
}

public class Controller2 {
    var callsCount = 0
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
        }
    }
}

public class Controller3 {
    var callsCount = 0
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.callsCount += 1
            EventService.get.sharedEvent.unsubscribe(self)
        }
    }
}

public class Controller4 {
    var callsCount = 0
    init() {
        EventService.get.sharedEvent.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
            EventService.get.sharedEvent.unsubscribeAll()
        }
    }
}

public class ControllerTS1 {
    var callsCount = 0
    init() {
        EventService.get.sharedEventTS.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
        }
    }
}

public class ControllerTS2 {
    var callsCount = 0
    init() {
        EventService.get.sharedEventTS.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
        }
    }
}

public class ControllerTS3 {
    var callsCount = 0
    init() {
        EventService.get.sharedEventTS.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.callsCount += 1
            EventService.get.sharedEventTS.unsubscribe(self)
        }
    }
}

public class ControllerTS4 {
    var callsCount = 0
    init() {
        EventService.get.sharedEventTS.subscribe(self) { [weak self] _ in
            self?.callsCount += 1
            EventService.get.sharedEventTS.unsubscribeAll()
        }
    }
}

