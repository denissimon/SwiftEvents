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
    
    // Events
    public let sharedEvent = Event<Int?>()
}
