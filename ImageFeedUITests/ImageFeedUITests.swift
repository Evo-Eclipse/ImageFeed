import XCTest

/// UI tests for the ImageFeed application
final class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    /// Tests the authentication flow
    /// - Verifies login process through Unsplash web authentication
    /// - Checks successful transition to feed after authentication
    func testAuth() throws {
        let userEmail = "YOUR_UNSPLASH_TEST_EMAIL_HERE"
        let userPassword = "YOUR_UNSPLASH_TEST_PASSWORD_HERE"
        
        let loginButton = app.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()
        
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))
        
        let emailTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 5))
        emailTextField.tap()
        emailTextField.typeText(userEmail)
        sleep(1)
        
        app.toolbars["Toolbar"].buttons["Next"].tap()
        sleep(2)
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText(userPassword)
        sleep(1)
        
        app.toolbars["Toolbar"].buttons["Done"].tap()
        sleep(2)
        
        let loginWebButton = webView.buttons["Login"]
        XCTAssertTrue(loginWebButton.waitForExistence(timeout: 5))
        loginWebButton.tap()
        
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.waitForExistence(timeout: 10))
        
        let firstCell = tableView.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
    }
    
    /// Tests the feed functionality
    /// - Verifies scrolling in the feed
    /// - Tests like/unlike functionality
    /// - Checks image detail view with zoom capabilities
    func testFeed() throws {
        let tablesQuery = app.tables
        XCTAssertTrue(tablesQuery.firstMatch.waitForExistence(timeout: 10))
        
        let cell = tablesQuery.cells.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        
        cell.swipeUp()
        sleep(2)
        
        let cellToLike = tablesQuery.cells.element(boundBy: 1)
        XCTAssertTrue(cellToLike.exists)
        
        let likeButton = cellToLike.buttons["Like"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        likeButton.tap()
        sleep(4)
        
        let unlikeButton = cellToLike.buttons["Unlike"]
        XCTAssertTrue(unlikeButton.waitForExistence(timeout: 5))
        unlikeButton.tap()
        sleep(4)
        
        cellToLike.tap()
        
        let fullScreenImage = app.scrollViews["ImageView"].images["FullImage"]
        XCTAssertTrue(fullScreenImage.waitForExistence(timeout: 10))
        
        fullScreenImage.pinch(withScale: 3.0, velocity: 1.0)
        sleep(1)
        
        fullScreenImage.pinch(withScale: 0.5, velocity: -1.0)
        sleep(1)
        
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.exists)
        backButton.tap()
        
        XCTAssertTrue(tablesQuery.firstMatch.waitForExistence(timeout: 5))
    }
    
    /// Tests the profile functionality
    /// - Verifies profile information display
    /// - Tests logout functionality
    func testProfile() throws {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        sleep(2)
        
        let profileName = app.staticTexts["Name"]
        XCTAssertTrue(profileName.exists)
        
        let username = app.staticTexts["Username"]
        XCTAssertTrue(username.exists)
        
        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(logoutButton.exists)
        logoutButton.tap()
        
        let alert = app.alerts["Пока, пока!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        
        alert.buttons["Да"].tap()
        
        let loginButton = app.buttons["Login"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
    }
}
