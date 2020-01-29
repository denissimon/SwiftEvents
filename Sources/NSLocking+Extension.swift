//
// NSLocking+Extension.swift
// https://github.com/denissimon/SwiftEvents
//
// Created by Denis Simon on 01/29/2020.
// Copyright © 2020 SwiftEvents. All rights reserved.
//

import Foundation

extension NSLocking {
    public func with<T>(handler: () -> T) -> T {
        self.lock()
        let result = handler()
        self.unlock()
        return result
    }
}
