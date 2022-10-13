//
//  File.swift
//  
//
//  Created by Carlos Henrique Gava on 12/10/22.
//

import XCTest
@testable import Scheduler

final class MonthTests: XCTestCase {
    func testIs() {
        let d = Date(year: 2019, month: 1, day: 1)
        XCTAssertTrue(d.is(.january(1), in: TimeZone.shanghai))
    }

    func testAsDateComponents() {
        let comps = Month.april(1).asDateComponents()
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 1)
    }

    func testDescription() {
        let md = Month.april(1)
        XCTAssertEqual(md.debugDescription, "Month: April 1st")
    }

    static var allTests = [
        ("testIs", testIs),
        ("testAsDateComponents", testAsDateComponents),
        ("testDescription", testDescription)
    ]
}
