//
//  SwiftEventsTests.swift
//  SwiftEvents
//
//  Created by Denis Simon on 05/29/2019.
//  Copyright © 2019 SwiftEvents. All rights reserved.
//

import XCTest
import SwiftEvents
#if os(Linux)
import Dispatch
#endif

class SwiftEventsTests: XCTestCase {
    
    var eventInt: Event<Int?>!
    var eventString: Event<String?>!
    var eventMultiValues: Event<(Int, String)?>!
    
    override func setUp() {
        super.setUp()
        
        eventInt = Event<Int?>()
        eventString = Event<String?>()
        eventMultiValues = Event<(Int, String)?>()
        
        EventService.get.sharedEvent.removeAllSubscribers()
        EventService.get.sharedEvent.resetTriggersCount()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrigger() {
        var intEventResult: Int? = nil
        var stringEventResult: String? = nil
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                intEventResult = data
            }
        })
        
        eventString.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                stringEventResult = data
            }
        })
        
        eventInt.trigger(1)
        eventString.trigger("test")
        
        XCTAssertEqual(intEventResult, 1)
        XCTAssertEqual(stringEventResult, "test")
    }
    
    func testTriggerNil() {
        var eventResult: Int? = nil
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            eventResult = data
        })
        
        eventInt.trigger(nil)
        
        XCTAssertEqual(eventResult, nil)
        XCTAssertEqual(eventInt.triggersCount, 1)
    }
    
    func testTriggerMultiValues() {
        var intArgument: Int? = nil
        var stringArgument: String? = nil
        
        eventMultiValues.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                intArgument = data.0
                stringArgument = data.1
            }
        })
        
        eventMultiValues.trigger((1, "test"))
        
        XCTAssertEqual(intArgument, 1)
        XCTAssertEqual(stringArgument, "test")
    }
    
    func testMultiTriggers() {
        var intEventResult: Int? = nil
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                intEventResult = data
            }
        })
        
        eventInt.trigger(1)
        eventInt.trigger(5)
        
        XCTAssertEqual(intEventResult, 5)
        XCTAssertEqual(eventInt.triggersCount, 2)
    }
    
    func testOneToManyTrigger() {
        var intEventResult: Int? = nil
        var handledCount = 0
        
        EventService.get.sharedEvent.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                intEventResult = data
                handledCount += 1
            }
        })
        
        EventService.get.sharedEvent.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                intEventResult = data + 1
                handledCount += 1
            }
        })
        
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(intEventResult, 2)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 1)
        XCTAssertEqual(handledCount, 2)
    }
    
    func testRemoveSubscriber() {
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.removeSubscriber(target: self)
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 0)
    }
    
    func testRemoveSubscriberUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.removeSubscriber(target: subscriber1)
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 1)
        XCTAssertEqual(subscriber1.handledCount + subscriber2.handledCount, 1)
    }
    
    func testRemoveAllSubscribers() {
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.removeAllSubscribers()
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 0)
    }
    
    func testRemoveAllSubscribersUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.removeAllSubscribers()
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 1)
        XCTAssertEqual(subscriber1.handledCount + subscriber2.handledCount, 0)
    }
    
    func testRemoveAllSubscribersDuringTriggering() {
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
                self.eventInt.removeAllSubscribers()
            }
        })
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.trigger(1)

        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 2)
    }
    
    func testGetSubscribersCount() {
        eventInt.addSubscriber(target: self, handler: { (self, _) in
        })
        eventInt.addSubscriber(target: self, handler: { (self, _) in
        })
        eventInt.addSubscriber(target: self, handler: { (self, _) in
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 3)
    }
    
    func testGetTriggersCount() {
        eventInt.addSubscriber(target: self, handler: { (self, _) in
        })
        
        eventInt.trigger(1)
        eventInt.trigger(1)
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.triggersCount, 3)
    }
    
    func testResetTriggersCount() {
        let _ = Controller1()
        let _ = Controller2()
        
        EventService.get.sharedEvent.trigger(1)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 1)
        
        EventService.get.sharedEvent.resetTriggersCount()
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 0)
    }
    
    func testResetTriggersCountDuringTriggering() {
        eventInt.addSubscriber(target: self, handler: { (self, _) in
            self.eventInt.resetTriggersCount()
        })
        
        eventInt.addSubscriber(target: self, handler: { (self, _) in
        })
        
        eventInt.trigger(1)
        XCTAssertEqual(eventInt.triggersCount, 0)
    }
    
    func testAutoRemoveWeakSubscribers() {
        var subscriber: Controller1? = Controller1()
        
        EventService.get.sharedEvent.trigger(1)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        
        subscriber = nil
        
        EventService.get.sharedEvent.trigger(1)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
    }
    
    func testTriggerFromDifferentThreads() {
        let subscriber = Controller1()
        
        // Trigger from Main thread
        EventService.get.sharedEvent.trigger(1)
        
        DispatchQueue.global(qos: .background).sync {
            // Trigger from Background thread
            EventService.get.sharedEvent.trigger(1)
        }
        
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 2)
        XCTAssertEqual(subscriber.handledCount, 2)
    }
    
    func testRemoveSubscriberFromBackgroundThread() {
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, handler: { (self, data) in
            if let data = data {
                handledCount += data
            }
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.removeSubscriber(target: self)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
    }
    
    func testAddSubscriberFromBackgroundThread() {
        var handledCount = 0
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.addSubscriber(target: self, handler: { (self, data) in
                if let data = data {
                    handledCount += data
                }
            })
        }
        
        eventInt.trigger(1)
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        XCTAssertEqual(eventInt.triggersCount, 2)
        XCTAssertEqual(handledCount, 2)
    }
    
    //////// onetime, queue, delay ////////////////////////////////////////////
    
    func testSubscribeOnetime() {
        eventInt.addSubscriber(target: self, onetime: true, handler: { (self, _) in
        })
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
    }
    
    func testRemoveSubscriberWhenSubscribingOnetime() {
        var handledCount = 0
        
        eventMultiValues.addSubscriber(target: self, onetime: true, handler: { (self, data) in
            self.eventMultiValues.removeSubscriber(target: self)
            if let data = data {
                handledCount += data.0
            }
        })
        
        XCTAssertEqual(eventMultiValues.subscribersCount, 1)
        
        eventMultiValues.trigger((1, "test"))
        
        XCTAssertEqual(eventMultiValues.subscribersCount, 0)
        XCTAssertEqual(eventMultiValues.triggersCount, 1)
        XCTAssertEqual(handledCount, 1)
    }
    
    func testSendingNotificationsOnBackgroundThread() {
        let promise = expectation(description: "handledCount = 2")
        
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, queue: .global(qos: .background), handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, false)
            if let data = data {
                handledCount += data
                if handledCount == 2 {
                    promise.fulfill()
                }
            }
        })
        
        eventInt.addSubscriber(target: self, queue: .global(qos: .background), handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, false)
            if let data = data {
                handledCount += data
                if handledCount == 2 {
                    promise.fulfill()
                }
            }
        })
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnMainThread() {
        let promise = expectation(description: "handledCount = 2")
        
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, queue: .main, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, true)
            if let data = data {
                handledCount += data
                if handledCount == 2 {
                    promise.fulfill()
                }
            }
        })
        
        eventInt.addSubscriber(target: self, queue: .main, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, true)
            if let data = data {
                handledCount += data
                if handledCount == 2 {
                    promise.fulfill()
                }
            }
        })
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnBackgroundThreadUsingCustomQueue() {
        let queue = DispatchQueue(label: "com.custom.serial.queue", qos: .background)
        
        var handledCount = 0
        
        eventInt.addSubscriber(target: self, queue: queue, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, false)
            if let data = data {
                handledCount += data
            }
        })
        
        eventInt.addSubscriber(target: self, queue: queue, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, false)
            if let data = data {
                handledCount += data
            }
        })
        
        eventInt.trigger(1)
        
        queue.sync {}
        
        XCTAssertEqual(handledCount, 2)
    }
    
    func testDelayedSendingNotifications() {
        var handledCount = 0
        
        let promise = expectation(description: "In the handler")
        
        eventInt.addSubscriber(target: self, delay: 1.0, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, false)
            if let data = data {
                handledCount = data
                promise.fulfill()
            }
        })
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 2)
        XCTAssertEqual(handledCount, 1)
    }
    
    func testDelayedSendingNotificationsOnMainQueue() {
        var handledCount = 0
        
        let promise = expectation(description: "In the handler")
        
        eventInt.addSubscriber(target: self, queue: .main, delay: 1.0, handler: { (self, data) in
            XCTAssertEqual(Thread.isMainThread, true)
            if let data = data {
                handledCount = data
                promise.fulfill()
            }
        })
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 2)
        XCTAssertEqual(handledCount, 1)
    }
    
    //////// KVO and bindings functionality ////////////////////////////////
    
    func testObservingProperties() {
        let str = Observable<String>("")
        
        var handledCount = 0
        var oldValue = ""
        
        str.didChanged.addSubscriber(target: self, handler: { (self, value) in
            handledCount += 1
            oldValue = value.1
        })
        
        str.value = "test1"
        str <<< "test2"
        
        XCTAssertEqual(handledCount, 2)
        XCTAssertEqual(str.value, "test2")
        XCTAssertEqual(oldValue, "test1")
    }
    
    func testObservingPropertiesWhenSubscribingOnetime() {
        let str = Observable<String>("")
        
        var handledCount = 0
        var oldValue = ""
        
        str.didChanged.addSubscriber(target: self, onetime: true, handler: { (self, value) in
            handledCount += 1
            oldValue = value.1
        })
        
        str.value = "test1"
        str <<< "test2"
        
        XCTAssertEqual(handledCount, 1)
        XCTAssertEqual(str.value, "test2")
        XCTAssertEqual(oldValue, "")
    }
    
    //////// testPerformance ///////////////////////////////////////////////////
    
    func testPerformance() {
        self.measure() {
            var handledCount = 0
            for _ in 0..<10 {
                eventMultiValues.addSubscriber(target: self, handler: { (self, data) in
                    if let data = data {
                        handledCount += data.0
                    }
                })
            }
            for _ in 0..<1000 {
                eventMultiValues.trigger((1, "test"))
            }
        }
    }
}

class Controller1 {
    
    var handledCount = 0
    
    init() {
        EventService.get.sharedEvent.addSubscriber(target: self, handler: { (self, _) in
            self.handledCount += 1
        })
    }
}

class Controller2 {
    
    var handledCount = 0
    
    init() {
        EventService.get.sharedEvent.addSubscriber(target: self, handler: { (self, _) in
            self.handledCount += 1
        })
    }
}
