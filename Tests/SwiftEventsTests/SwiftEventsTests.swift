//
//  SwiftEventsTests.swift
//  https://github.com/denissimon/SwiftEvents
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
    
    private func updateValue(_ value: String) {
        XCTAssertEqual(observableString.value, "new value")
        XCTAssertEqual(observableString.observersCount, 1)
        XCTAssertEqual(observableString.triggersCount, 1)
    }
    
    func testBindToObservable() {
        observableString.bind(self) { [weak self] in self?.updateValue($0) }
        observableString.value = "new value"
    }
    
    func testMultiTriggerObservable() {
        var callsCount = 0
        
        observableString.bind(self) { _ in callsCount += 1 }
        
        observableString.value = "value1"
        observableString <<< "value2"
        
        XCTAssertEqual(callsCount, 2)
        XCTAssertEqual(observableString.triggersCount, 2)
        XCTAssertEqual(observableString.value, "value2")
    }

    func testUnbindFromObservable() {
        var callsCount = 0
        
        observableString.bind(self) { _ in callsCount += 1 }
        
        observableString.unbind(self)
        
        observableString.value = "test"
        
        XCTAssertEqual(callsCount, 0)
        XCTAssertEqual(observableString.triggersCount, 1)
        XCTAssertEqual(observableString.value, "test")
    }
    
    func testUnbindAllFromObservable() {
        var callsCount = 0
        
        observableString.bind(self) { _ in callsCount += 1 }
        observableString.bind(self) { _ in callsCount += 1 }
        observableString.value = "value1"
        
        XCTAssertEqual(callsCount, 2)
        XCTAssertEqual(observableString.triggersCount, 1)
        XCTAssertEqual(observableString.value, "value1")
        
        observableString.unbindAll()
        
        observableString.value = "value2"
        
        XCTAssertEqual(callsCount, 2)
        XCTAssertEqual(observableString.triggersCount, 2)
        XCTAssertEqual(observableString.value, "value2")
    }
    
    func testSubscribeAndNotify() {
        var intEventResult: Int? = nil
        var stringEventResult: String? = nil
        var multiValueResult: (Int, String)? = nil
        
        eventInt.subscribe(self) { data in intEventResult = data }
        eventString.subscribe(self) { data in stringEventResult = data }
        eventMultiValues.subscribe(self) { data in multiValueResult = data }
        
        eventInt.notify(1)
        eventString.notify("test")
        eventMultiValues.notify((1, "test"))
        
        XCTAssertEqual(intEventResult, 1)
        XCTAssertEqual(stringEventResult, "test")
        XCTAssertEqual(multiValueResult?.0, 1)
        XCTAssertEqual(multiValueResult?.1, "test")
    }
    
    func testSubscribeAndNotifyNil() {
        var intEventResult: Int? = nil
        
        eventInt.subscribe(self) { data in intEventResult = data }
        
        eventInt.notify(nil)
        
        XCTAssertEqual(intEventResult, nil)
        XCTAssertEqual(eventInt.triggersCount, 1)
    }
    
    func testSubscribeAndMultiNotify() {
        var intEventResult: Int? = nil
        
        eventInt.subscribe(self) { data in intEventResult = data }
        
        eventInt.notify(1)
        eventInt.notify(5)
        
        XCTAssertEqual(intEventResult, 5)
        XCTAssertEqual(eventInt.triggersCount, 2)
    }
    
    func testOneToManyNotifications() {
        var intEventResult: Int? = nil
        var callsCount = 0
        
        EventService.get.sharedEvent.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data
            callsCount += 1
        }
        
        EventService.get.sharedEvent.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data + 1
            callsCount += 1
        }
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(intEventResult, 2)
        XCTAssertEqual(callsCount, 2)
    }
    
    func testUnsibscribe() {
        var callsCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.unsubscribe(self)
        eventInt.notify(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(callsCount, 0)
    }
    
    func testUnsibscribeUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.unsubscribe(subscriber1)
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount, 1)
    }
    
    func testOneTimeNotification() {
        var callsCount = 0
        
        // The handler of this subscriber will be executed only once
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            self.eventInt.unsubscribe(self)
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        eventInt.notify(1)

        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(callsCount, 1)
    }
    
    func testNTimeNotifications() {
        var callsCount = 0
        let n = 3
        
        // The handler of this subscriber will be executed only 3 times
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            if self.eventInt.triggersCount >= n {
                self.eventInt.unsubscribe(self)
            }
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        for _ in 1...n*2 {
            eventInt.notify(1)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, n*2)
        XCTAssertEqual(callsCount, n)
    }
    
    func testUnsibscribeAll() {
        var callsCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.unsubscribeAll()
        eventInt.notify(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(callsCount, 0)
    }
    
    func testUnsibscribeAllUsingEventService() {
        let subscriber1 = Controller1()
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.unsubscribeAll()
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount, 0)
    }
    
    func testUnsibscribeAllDuringTriggering() {
        var callsCount = 0
        
        eventInt.subscribe(self) { [weak self] data in
            guard let self = self, let data = data else { return }
            self.eventInt.unsubscribeAll()
            callsCount += data
        }
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 2)
        
        eventInt.notify(1)

        XCTAssertEqual(eventInt.subscribersCount, 0)
        XCTAssertEqual(eventInt.triggersCount, 1)
        XCTAssertEqual(callsCount, 2)
    }
    
    func testOneTimeNotificationWithMultipleSubscribers() {
        let subscriber1 = Controller1()
        let subscriber3 = Controller3() // unsubscribe itself from the Event during triggering
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 3)
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount + subscriber3.callsCount, 3)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        XCTAssertEqual(subscriber1.callsCount, 2)
        XCTAssertEqual(subscriber2.callsCount, 2)
        XCTAssertEqual(subscriber3.callsCount, 1)
    }
    
    func testUnsibscribeAllDuringTriggeringWithMultipleSubscribers() {
        let subscriber1 = Controller1()
        let subscriber4 = Controller4() // unsubscribe all subscribers from the Event during triggering
        let subscriber2 = Controller2()
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 3)
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount + subscriber4.callsCount, 3)
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 0)
        XCTAssertEqual(subscriber1.callsCount, 1)
        XCTAssertEqual(subscriber2.callsCount, 1)
        XCTAssertEqual(subscriber4.callsCount, 1)
    }
    
    func testGetSubscribersCount() {
        for _ in 0...2 {
            eventInt.subscribe(self) { _ in }
        }
        XCTAssertEqual(eventInt.subscribersCount, 3)
        XCTAssertEqual(eventInt.triggersCount, 0)
    }
    
    func testGetTriggersCount() {
        eventInt.subscribe(self) { _ in }
        
        for _ in 0...2 {
            eventInt.notify(1)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        XCTAssertEqual(eventInt.triggersCount, 3)
    }
    
    func testNotifyFromDifferentThreads() {
        let subscriber = Controller1()
        
        // Notify from the main thread
        EventService.get.sharedEvent.notify(1)
        
        DispatchQueue.global(qos: .background).sync {
            // Notify from a background thread
            EventService.get.sharedEvent.notify(1)
        }
        
        XCTAssertEqual(subscriber.callsCount, 2)
    }
    
    func testUnsubscribeOnBackgroundThread() {
        var callsCount = 0
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            callsCount += data
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.unsubscribe(self)
        }
        
        XCTAssertEqual(eventInt.subscribersCount, 0)
    }
    
    func testSubscribeOnBackgroundThread() {
        var callsCount = 0
        
        DispatchQueue.global(qos: .background).sync {
            self.eventInt.subscribe(self) { data in
                guard let data = data else { return }
                callsCount += data
            }
        }
        
        eventInt.notify(1)
        eventInt.notify(1)
        
        XCTAssertEqual(eventInt.subscribersCount, 1)
        XCTAssertEqual(eventInt.triggersCount, 2)
        XCTAssertEqual(callsCount, 2)
    }
    
    func testSendingNotificationsOnBackgroundThread() {
        let promise = expectation(description: "callsCount = 2")
        
        var callsCount = 0
        
        eventInt.subscribe(self, queue: .global(qos: .background)) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            callsCount += data
            if callsCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.subscribe(self, queue: .global(qos: .background)) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            callsCount += data
            if callsCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.notify(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnMainThread() {
        let promise = expectation(description: "callsCount = 2")
        
        var callsCount = 0
        
        eventInt.subscribe(self, queue: .main) { data in
            XCTAssertEqual(Thread.isMainThread, true)
            guard let data = data else { return }
            callsCount += data
            if callsCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.subscribe(self, queue: .main) { data in
            XCTAssertEqual(Thread.isMainThread, true)
            guard let data = data else { return }
            callsCount += data
            if callsCount == 2 {
                promise.fulfill()
            }
        }
        
        eventInt.notify(1)
        wait(for: [promise], timeout: 1)
    }
    
    func testSendingNotificationsOnBackgroundThreadUsingCustomQueue() {
        let queue = DispatchQueue(label: "com.custom.serial.queue", qos: .background)
        
        var callsCount = 0
        
        eventInt.subscribe(self, queue: queue) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            callsCount += data
        }
        
        eventInt.subscribe(self, queue: queue) { data in
            XCTAssertEqual(Thread.isMainThread, false)
            guard let data = data else { return }
            callsCount += data
        }
        
        eventInt.notify(1)
        
        queue.sync {}
        
        XCTAssertEqual(callsCount, 2)
    }
    
    func testDelayedSendingNotifications() {
        var callsCount = 0
        
        let promise = expectation(description: "In the handler")
        
        eventInt.subscribe(self) { data in
            guard let data = data else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                callsCount = data
                promise.fulfill()
            }
        }
        
        eventInt.notify(1)
        wait(for: [promise], timeout: 1)
        XCTAssertEqual(callsCount, 1)
    }
    
    func testAutoRemoveDeallocatedSubscribersAfterNotify() {
        // Controller1 subscribes to the sharedEvent during init()
        var subscriber1: Controller1? = Controller1()
        // Controller2 subscribes to the sharedEvent during init()
        var subscriber2: Controller2? = Controller2()
        
        EventService.get.sharedEvent.notify(1) // a check is made for deallocated subscribers
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 2)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 1)
        XCTAssertEqual(subscriber1?.callsCount, 1)
        XCTAssertEqual(subscriber2?.callsCount, 1)
        
        subscriber1 = nil
        
        EventService.get.sharedEvent.notify(1) // a check is made for deallocated subscribers
        XCTAssertEqual(EventService.get.sharedEvent.subscribersCount, 1)
        XCTAssertEqual(EventService.get.sharedEvent.triggersCount, 2)
        XCTAssertEqual(subscriber1?.callsCount, nil)
        XCTAssertEqual(subscriber2?.callsCount, 2)
    }
    
    func testPerformance() {
        self.measure() {
            var callsCount = 0
            
            for _ in 0..<10 {
                eventMultiValues.subscribe(self) { data in
                    guard let data = data else { return }
                    callsCount += data.0
                }
            }
            
            for _ in 0..<1000 {
                eventMultiValues.notify((1, "test"))
            }
            
            XCTAssertEqual(callsCount, 10000)
        }
    }
}
