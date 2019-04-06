

import XCTest

class Popcorn_TimeUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        let moviesCount = app.collectionViews.element.children(matching: .cell)
        let count = NSPredicate(format: "count > 0")
        
        expectation(for: count, evaluatedWith: moviesCount, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.right)
        
        
        XCTAssert(app.navigationBars["PopcornTime.MoviesView"].buttons["Sort"].hasFocus)
        XCUIRemote.shared.press(.select)
        
        let sortDialog = app.sheets["Select a filter to sort by"]
        let exists = NSPredicate(format: "exists == 1")
        
        expectation(for: exists, evaluatedWith: sortDialog, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCTAssert(app.sheets["Select a filter to sort by"].otherElements["Recently Added"].hasFocus)
        XCUIRemote.shared.press(.select)
        
        expectation(for: count, evaluatedWith: moviesCount, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
    }
    
}
