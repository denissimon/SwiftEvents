//
//  SwiftEventsTSTests.swift
//  https://github.com/denissimon/SwiftEvents
//
//  Created by Denis Simon on 05/29/2019.
//
//  MIT License (https://github.com/denissimon/SwiftEvents/blob/master/LICENSE)
//

import XCTest
import SwiftEvents
#if os(Linux)
import Dispatch
#endif

class SwiftEventsTSTests: XCTestCase {
    
    struct Some {}
    
    var eventInt: EventTS<Int?> = EventTS()
    var eventString: EventTS<String?> = EventTS()
    var eventMultiValues: EventTS<(Int, String)?> = EventTS()
    var eventSome: EventTS<Some> = EventTS()
    
    var observableString: ObservableTS<String> = ObservableTS("")
    var observableSome: ObservableTS<Some> = ObservableTS(Some())
    
    override func setUp() {
        super.setUp()
        
        eventInt = EventTS()
        eventString = EventTS()
        eventMultiValues = EventTS()
        eventSome = EventTS()
        
        observableString = ObservableTS("")
        observableSome = ObservableTS(Some())
        
        EventService.get.sharedEventTS.unsubscribeAll()
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
        
        EventService.get.sharedEventTS.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data
            callsCount += 1
        }
        
        EventService.get.sharedEventTS.subscribe(self) { data in
            guard let data = data else { return }
            intEventResult = data + 1
            callsCount += 1
        }
        
        EventService.get.sharedEventTS.notify(1)
        
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
        let subscriber1 = ControllerTS1()
        let subscriber2 = ControllerTS2()
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 2)
        
        EventService.get.sharedEventTS.unsubscribe(subscriber1)
        EventService.get.sharedEventTS.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 1)
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
        let subscriber1 = ControllerTS1()
        let subscriber2 = ControllerTS2()
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 2)
        
        EventService.get.sharedEventTS.unsubscribeAll()
        EventService.get.sharedEventTS.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 0)
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
        let subscriber1 = ControllerTS1()
        let subscriber3 = ControllerTS3() // unsubscribe itself from the Event during triggering
        let subscriber2 = ControllerTS2()
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 3)
        
        EventService.get.sharedEventTS.notify(1)
        
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount + subscriber3.callsCount, 3)
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 2)
        
        EventService.get.sharedEventTS.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 2)
        XCTAssertEqual(subscriber1.callsCount, 2)
        XCTAssertEqual(subscriber2.callsCount, 2)
        XCTAssertEqual(subscriber3.callsCount, 1)
    }
    
    func testUnsibscribeAllDuringTriggeringWithMultipleSubscribers() {
        let subscriber1 = ControllerTS1()
        let subscriber4 = ControllerTS4() // unsubscribe all subscribers from the Event during triggering
        let subscriber2 = ControllerTS2()
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 3)
        
        EventService.get.sharedEventTS.notify(1)
        
        XCTAssertEqual(subscriber1.callsCount + subscriber2.callsCount + subscriber4.callsCount, 3)
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 0)
        
        EventService.get.sharedEvent.notify(1)
        
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 0)
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
        let subscriber = ControllerTS1()
        
        // Notify from the main thread
        EventService.get.sharedEventTS.notify(1)
        
        DispatchQueue.global(qos: .background).sync {
            // Notify from a background thread
            EventService.get.sharedEventTS.notify(1)
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
        // ControllerTS1 subscribes to the sharedEventTS during init()
        var subscriber1: ControllerTS1? = ControllerTS1()
        // ControllerTS2 subscribes to the sharedEventTS during init()
        let subscriber2: ControllerTS2? = ControllerTS2()
        
        EventService.get.sharedEventTS.notify(1) // a check is made for deallocated subscribers
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 2)
        XCTAssertEqual(EventService.get.sharedEventTS.triggersCount, 1)
        XCTAssertEqual(subscriber1?.callsCount, 1)
        XCTAssertEqual(subscriber2?.callsCount, 1)
        
        subscriber1 = nil
        
        EventService.get.sharedEventTS.notify(1) // a check is made for deallocated subscribers
        XCTAssertEqual(EventService.get.sharedEventTS.subscribersCount, 1)
        XCTAssertEqual(EventService.get.sharedEventTS.triggersCount, 2)
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
    
    func testThreadSafety() {
        eventSome.subscribe(self) { _ in }
        observableSome.bind(self) { _ in }
        
        DispatchQueue.concurrentPerform(iterations: 100_000) { _ in
            eventSome.notify(Some())
            observableSome <<< Some()
        }
        
        XCTAssertEqual(eventSome.triggersCount, 100_000)
        XCTAssertEqual(observableSome.triggersCount, 100_000)
    }
    
    func testThreadSafety2() {
        DispatchQueue.concurrentPerform(iterations: 100_000) { _ in
            eventSome.subscribe(self) { _ in }
            observableSome.bind(self) { _ in }
        }
        
        XCTAssertEqual(eventSome.subscribersCount, 100_000)
        XCTAssertEqual(observableSome.observersCount, 100_000)
    }
        
    func testThreadSafety3() {
        
        class ViewController {}
        
        // One target object as observer
        let observer = ViewController()
        
        DispatchQueue.concurrentPerform(iterations: 100_000) { _ in
            observableSome.bind(observer) { _ in }
        }
        
        XCTAssertEqual(observableSome.observersCount, 100_000)
        
        // Because the target observer object is the same here,
        // then this line will be equivalent to calling unbindAll()
        observableSome.unbind(observer)
        
        XCTAssertEqual(observableSome.observersCount, 0)
    }
    
    func testThreadSafety4() {
        
        class TestClass {}
        
        // Various target objects as observers
        var observers = [TestClass]()
        
        let stateLock = NSLock()
        
        DispatchQueue.concurrentPerform(iterations: 10000) { _ in
            let observer = TestClass()
            observableSome.bind(observer) { _ in }
            
            stateLock.lock()
            observers.append(observer)
            stateLock.unlock()
        }
        
        XCTAssertEqual(observableSome.observersCount, 10000)
        
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            if let randomObserver = observers.randomElement() {
                observableSome.unbind(randomObserver)
                
                stateLock.lock()
                observers = observers.filter { $0 !== randomObserver }
                stateLock.unlock()
            }
        }
        
        XCTAssertEqual(observableSome.observersCount, 9900)
    }
}
