//
//  File.swift
//  
//
//  Created by Carlos Henrique Gava on 12/10/22.
//

import XCTest
@testable import Scheduler

final class WeekTests: XCTestCase {

    func testIs() {
        let d = Date(year: 2019, month: 1, day: 1)
        XCTAssertTrue(d.is(.tuesday, in: TimeZone.shanghai))
    }

    func testAsDateComponents() {
        XCTAssertEqual(Week.monday.asDateComponents().weekday!, 2)
    }

    func testDescription() {
        let wd = Week.tuesday
        XCTAssertEqual(wd.debugDescription, "Week: Tuesday")
    }

    static var allTests = [
        ("testIs", testIs),
        ("testAsDateComponents", testAsDateComponents),
        ("testDescription", testDescription)
    ]
}
