import XCTest
@testable import SwiftEvents

class SwiftEventsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftEvents().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftEventsTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
