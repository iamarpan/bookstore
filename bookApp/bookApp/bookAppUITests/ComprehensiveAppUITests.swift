// ComprehensiveAppUITests.swift
// Full flow UI tests for the bookApp — covering Authentication, Navigation, and Core Features.

import XCTest

final class ComprehensiveAppUITests: XCTestCase {

    var app: XCUIApplication!
    let testPhoneNumber = "8888888888"
    let testOTP = "123456" // Common test OTP, adjust if necessary

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testFullAppLifeCycle() throws {
        // 1. Authentication Flow
        try performLogin()

        // 2. Tab Navigation & View Verification
        try verifyTabs()

        // 3. Action: Search for a book on Home
        try verifySearch()

        // 4. Action: Add a book (partially, up to form validation)
        try verifyAddBookForm()

        // 5. Action: Logout
        try performLogout()
    }

    // MARK: - Helper Methods

    private func performLogin() throws {
        let phoneField = app.textFields["phone_number_field"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 10), "Phone Number field should exist")
        
        phoneField.tap()
        phoneField.typeText(testPhoneNumber)

        let sendOTPButton = app.buttons["send_otp_button"]
        XCTAssertTrue(sendOTPButton.isEnabled, "Send OTP button should be enabled for valid phone")
        sendOTPButton.tap()

        let otpField = app.textFields["otp_field"]
        XCTAssertTrue(otpField.waitForExistence(timeout: 10), "OTP field should appear after sending OTP")
        
        otpField.tap()
        otpField.typeText(testOTP)

        let verifyOTPButton = app.buttons["verify_otp_button"]
        XCTAssertTrue(verifyOTPButton.isEnabled, "Verify OTP button should be enabled")
        verifyOTPButton.tap()

        // Handle possible Registration screen if new user
        let completeRegistrationButton = app.buttons["complete_registration_button"]
        if completeRegistrationButton.waitForExistence(timeout: 5) {
            let nameField = app.textFields["Enter your full name"]
            if nameField.exists {
                nameField.tap()
                nameField.typeText("Test User")
            }
            completeRegistrationButton.tap()
        }

        // Verify we landed on Home
        let homeNavBar = app.navigationBars["BookShare"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: 15), "Should reach Home screen after login")
    }

    private func verifyTabs() throws {
        let tabs = ["Home", "Add", "Groups", "Library", "Alerts", "Profile"]
        
        for tab in tabs {
            let tabButton = app.buttons[tab]
            XCTAssertTrue(tabButton.exists, "Tab \(tab) should exist")
            tabButton.tap()
            
            // Short sleep to allow UI to transition
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify specific navigation titles or elements for each tab
            switch tab {
            case "Home":
                XCTAssertTrue(app.navigationBars["BookShare"].exists)
            case "Add":
                XCTAssertTrue(app.navigationBars["Add Book"].exists)
            case "Groups":
                XCTAssertTrue(app.navigationBars["My Groups"].exists)
            case "Library":
                XCTAssertTrue(app.navigationBars["My Library"].exists)
            case "Alerts":
                XCTAssertTrue(app.navigationBars["Notifications"].exists)
            case "Profile":
                XCTAssertTrue(app.navigationBars["Profile"].exists)
            default:
                break
            }
        }
    }

    private func verifySearch() throws {
        // Go back to Home
        app.buttons["Home"].tap()
        
        let searchField = app.textFields["Search books, authors..."]
        XCTAssertTrue(searchField.exists, "Search bar should exist on Home")
        
        searchField.tap()
        searchField.typeText("Swift")
        
        // Check if any book tile exists or just verify search action doesn't crash
        // In a real test, we might check for specific results if we have mock data
    }

    private func verifyAddBookForm() throws {
        app.buttons["Add"].tap()
        
        let titleField = app.textFields["Book Title"]
        XCTAssertTrue(titleField.exists)
        
        titleField.tap()
        titleField.typeText("Test UI Book")
        
        let authorField = app.textFields["Author"]
        XCTAssertTrue(authorField.exists)
        authorField.tap()
        authorField.typeText("UI Test Author")
        
        // We won't actually submit to avoid cluttering real DB if this is pointing to production
        // But we verify the fields are interactable
    }

    private func performLogout() throws {
        app.buttons["Profile"].tap()
        
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign Out button should exist in Profile")
        signOutButton.tap()
        
        let confirmButton = app.alerts["Sign Out"].buttons["Sign Out"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Confirmation alert should appear")
        confirmButton.tap()
        
        // Verify back at Auth screen
        let phoneField = app.textFields["phone_number_field"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 10), "Should be back at Auth screen after logout")
    }
}
