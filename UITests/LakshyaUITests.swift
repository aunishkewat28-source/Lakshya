import XCTest

final class LakshyaUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testDashboardShowsCoreSections() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.staticTexts["lakshya.heroTitle"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.otherElements["lakshya.focusTimerCard"].exists)
    XCTAssertTrue(app.staticTexts["lakshya.alarmBoard"].exists)
    XCTAssertTrue(app.buttons["lakshya.timerStartButton"].exists)
  }

  func testUserCanAddAlarmFromComposer() throws {
    let app = XCUIApplication()
    app.launch()

    let nameField = app.textFields["lakshya.addAlarmNameField"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))

    nameField.tap()
    nameField.typeText("Study Sprint\n")
    app.buttons["lakshya.addAlarmButton"].tap()

    XCTAssertTrue(app.staticTexts["Study Sprint"].waitForExistence(timeout: 5))
  }
}
