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
    
    var eventInt: Event<Int?> = Event()
    var eventString: Event<String?> = Event()
    var eventMultiValues: Event<(Int, String)?> = Event()
    var observableString: Observable<String> = Observable("")
    
    override func setUp() {
        super.setUp()
        
        eventInt = Event()
        eventString = Event()
        eventMultiValues = Event()
        observableString = Observable("")
        
        EventService.get.sharedEvent.unsubscribeAll()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrigger() {
        var intEventResult: Int? = nil
        var stringEventResult: String? = nil
        
        eventInt.subscribe(self) { data in intEventResult = data }
        
        eventString.subscribe(self) { data in stringEventResult = data }
        
        eventInt.trigger(1)
        eventString.trigger("test")
        
        XCTAssertEqual(intEventResult, 1)
        XCTAssertEqual(stringEventResult, "test")
    }
    
    func testTriggerNil() {
        var eventResult: Int? = nil
        
        eventInt.subscribe(self) { data in eventResult = data }
        
        eventInt.trigger(nil)
        
        XCTAssertEqual(eventResult, nil)
        XCTAssertEqual(eventInt.triggersCount, 1)
    }
    
    func testTriggerMultiValues() {
        var intArgument: Int? = nil
        var stringArgument: String? = nil
        
        eventMultiValues.subscribe(self) { data in
            guard let data = data else { return }
            intArgument = data.0
            stringArgument = data.1
        }
        
        eventMultiValues.trigger((1, "test"))
        
        XCTAssertEqual(intArgument, 1)
        XCTAssertEqual(stringArgument, "test")
    }
    
    func testMultiTriggers() {
        var intEventResult: Int? = nil
        
        eventInt.subscribe(self) { data in intEventResult = data }
        
        eventInt.trigger(1)
        eventInt.trigger(5)
        
        XCTAssertEqual(intEventResult, 5)
        XCTAssertEqual(eventInt.triggersCount, 2)
    }
    
    func testOneToManyTrigger() {
        var intEventResult: Int? = nil
        var handledCount = 0
        
        EventService.get.sharedEvent.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data
            handledCount += 1
        }
        
        EventService.get.sharedEvent.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data + 1
            handledCount += 1
        }
        
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(intEventResult, 2)
        XCTAssertEqual(handledCount, 2)
    }
    
    func testRemoveSubscriber() {
        var handledCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            handledCount += data
        }
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.unsubscribe(self)
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 0)
    }
    
    func testRemoveSubscriberUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.unsubscribe(subscriber1)
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        XCTAssertEqual(subscriber1.handledCount + subscriber2.handledCount, 1)
    }
    
    func testRemoveSubscriberDuringTriggering() {
        var handledCount = 0
        
        // The handler of this subscriber will be executed only once
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            self.eventInt.unsubscribe(self)
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        eventInt.trigger(1)

        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 1)
    }
    
    func testNTimeNotifications() {
        var handledCount = 0
        let n = 3
        
        // The handler of this subscriber will be executed only 3 times
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            if self.eventInt.triggersCount == n {
                self.eventInt.unsubscribe(self)
            }
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        for _ in 1...n*2 {
            eventInt.trigger(1)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, n*2)
        XCTAssertEqual(handledCount, n)
    }
    
    func testRemoveAllSubscribers() {
        var handledCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            handledCount += data
        }
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.unsubscribeAll()
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 0)
    }
    
    func testRemoveAllSubscribersUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.unsubscribeAll()
        EventService.get.sharedEvent.trigger(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
        XCTAssertEqual(subscriber1.handledCount + subscriber2.handledCount, 0)
    }
    
    func testRemoveAllSubscribersDuringTriggering() {
        var handledCount = 0
        
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            self.eventInt.unsubscribeAll()
            handledCount += data
        }
        
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.trigger(1)

        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(handledCount, 2)
    }
    
    func testGetSubscribersCount() {
        for _ in 0...2 {
            eventInt.subscribe(self) { _ in }
        }
        XCTAssertEqual(eventInt.subscribersCount, 3)
    }
    
    func testGetTriggersCount() {
        eventInt.subscribe(self) { _ in }
        
        for _ in 0...2 {
            eventInt.trigger(1)
        }
        
        XCTAssertEqual(eventInt.triggersCount, 3)
    }
    
    func testTriggerFromDifferentThreads() {
        let subscriber = Controller1()
        
        // Trigger from the main thread
        EventService.get.sharedEvent.trigger(1)
        
        DispatchQueue.global(qos: .background).sync {
            // Trigger from a background thread
            EventService.get.sharedEvent.trigger(1)
        }
        
        XCTAssertEqual(subscriber.handledCount, 2)
    }
    
    func testRemoveSubscriberFromBackgroundThread() {
        var handledCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            handledCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.unsubscribe(self)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
    }
    
    func testAddSubscriberFromBackgroundThread() {
        var handledCount = 0
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.subscribe(self) { data in
                guard let data = data else { return }
                handledCount += data
            }
        }
        
        eventInt.trigger(1)
        eventInt.trigger(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        XCTAssertEqual(eventInt.triggersCount, 2)
        XCTAssertEqual(handledCount, 2)
    }
    
    func testSendingNotificationsOnBackgroundThread() {
        let promise = expectation(description: "handledCount = 2")
        
        var handledCount = 0
        
        eventInt.subscribe(self, queue: .global(qos: .background)) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            handledCount += data
            if handledCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.subscribe(self, queue: .global(qos: .background)) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            handledCount += data
            if handledCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnMainThread() {
        let promise = expectation(description: "handledCount = 2")
        
        var handledCount = 0
        
        eventInt.subscribe(self, queue: .main) { data in
            XCTAssertEqual(Thread.isMainThread, true)
            guard let data = data else { return }
            handledCount += data
            if handledCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.subscribe(self, queue: .main) { data in
            XCTAssertEqual(Thread.isMainThread, true)
            guard let data = data else { return }
            handledCount += data
            if handledCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnBackgroundThreadUsingCustomQueue() {
        let queue = DispatchQueue(label: "com.custom.serial.queue", qos: .background)
        
        var handledCount = 0
        
        eventInt.subscribe(self, queue: queue) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            handledCount += data
        }
        
        eventInt.subscribe(self, queue: queue) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            handledCount += data
        }
        
        eventInt.trigger(1)
        
        queue.sync {}
        
        XCTAssertEqual(handledCount, 2)
    }
    
    func testDelayedSendingNotifications() {
        var handledCount = 0
        
        let promise = expectation(description: "In the handler")
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                handledCount = data
                promise.fulfill()
            }
        }
        
        eventInt.trigger(1)
        wait(for: [promise], timeout: 1)
        XCTAssertEqual(handledCount, 1)
    }
    
    func testAutoRemoveDealocatedSubscribers() {
        var subscriber: Controller1? = Controller1()
        
        EventService.get.sharedEvent.trigger(1)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        
        subscriber = nil
        
        EventService.get.sharedEvent.trigger(1)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
    }
    
    func testBindToObservable() {
        var handledCount = 0
        
        observableString.bind(self) { _ in handledCount += 1 }
        
        observableString.value = "value1"
        observableString <<< "value2"
        
        XCTAssertEqual(handledCount, 2)
        XCTAssertEqual(observableString.value, "value2")
    }

    func testUnbindFromObservable() {
        var handledCount = 0
        
        observableString.bind(self) { _ in handledCount += 1 }
        
        observableString.unbind(self)
        
        observableString.value = "test"
        
        XCTAssertEqual(handledCount, 0)
        XCTAssertEqual(observableString.value, "test")
    }
    
    func testUnbindAllFromObservable() {
        var handledCount = 0
        
        observableString.bind(self) { _ in handledCount += 1 }
        observableString.bind(self) { _ in handledCount += 1 }
        observableString.value = "value1"
        
        XCTAssertEqual(handledCount, 2)
        XCTAssertEqual(observableString.value, "value1")
        
        observableString.unbindAll()
        
        observableString.value = "value2"
        
        XCTAssertEqual(handledCount, 2)
        XCTAssertEqual(observableString.value, "value2")
    }
    
    func testPerformance() {
        self.measure() {
            var handledCount = 0
            for _ in 0..<10 {
                eventMultiValues.subscribe(self) { data in
                    guard let data = data else { return }
                    handledCount += data.0
                }
            }
            for _ in 0..<1000 {
                eventMultiValues.trigger((1, "test"))
            }
        }
    }
}
