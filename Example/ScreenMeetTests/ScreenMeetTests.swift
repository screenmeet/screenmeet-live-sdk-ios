//
//  ScreenMeetTests.swift
//  ScreenMeetTests
//
//  Created by Apple on 5/28/21.
//

import XCTest
import ScreenMeetSDK

class ScreenMeetTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConnectionState() throws {
        XCTAssertEqual(ScreenMeet.getConnectionState() == .disconnected(.callNotStarted), true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
