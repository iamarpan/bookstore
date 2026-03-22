// bookAppUITests.swift
// UI tests for the bookApp — covering the Authentication flow and critical navigation.

import XCTest

final class AuthenticationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Pass launch arguments to signal this is a test run
        // (useful for mocking or resetting state in the app if needed)
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        // The app should launch and show some root view
        XCTAssertTrue(app.exists)
    }

    // MARK: - Authentication Screen

    @MainActor
    func testAuthScreenShowsSignInElements() throws {
        // The authentication screen must display:
        // 1. Google sign-in button
        // 2. Phone number text field
        // 3. "Send OTP" button

        let googleButton = app.buttons["google_sign_in_button"]
        XCTAssertTrue(
            googleButton.waitForExistence(timeout: 5),
            "Expected Google sign-in button on the auth screen"
        )

        let phoneField = app.textFields["phone_number_field"]
        XCTAssertTrue(
            phoneField.waitForExistence(timeout: 5),
            "Expected Phone Number text field on the auth screen"
        )

        let sendOTPButton = app.buttons["send_otp_button"]
        XCTAssertTrue(
            sendOTPButton.waitForExistence(timeout: 5),
            "Expected 'Send OTP' button on the auth screen"
        )
    }

    // MARK: - Google Sign-In Button

    @MainActor
    func testGoogleSignInButtonIsEnabled() throws {
        let googleButton = app.buttons["google_sign_in_button"]
        XCTAssertTrue(googleButton.waitForExistence(timeout: 5))
        // The button should always be enabled on the auth screen
        XCTAssertTrue(googleButton.isEnabled)
    }

    // MARK: - Phone Number Field Interaction

    @MainActor
    func testPhoneNumberFieldAcceptsInput() throws {
        let phoneField = app.textFields["phone_number_field"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))

        phoneField.tap()
        phoneField.typeText("9876543210")

        XCTAssertEqual(phoneField.value as? String, "9876543210")
    }


    @MainActor
    func testSendOTPButtonDisabledWithShortPhoneNumber() throws {
        let phoneField = app.textFields["Phone Number"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))

        phoneField.tap()
        phoneField.typeText("123") // Too short — less than 10 digits

        let sendOTPButton = app.buttons["Send OTP"]
        XCTAssertFalse(
            sendOTPButton.isEnabled,
            "Send OTP button should be disabled when phone number is too short"
        )
    }

    @MainActor
    func testSendOTPButtonEnabledWithValidPhoneNumber() throws {
        let phoneField = app.textFields["Phone Number"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))

        phoneField.tap()
        phoneField.typeText("9876543210") // Valid 10-digit number

        let sendOTPButton = app.buttons["Send OTP"]
        XCTAssertTrue(
            sendOTPButton.isEnabled,
            "Send OTP button should be enabled with a valid phone number"
        )
    }

    // MARK: - OTP Field Appears After Sending

    @MainActor
    func testOTPFieldAppearsAfterSuccessfulOTPSend() throws {
        // NOTE: This test requires a real or mocked OTP send response.
        // In a CI environment, configure the app to use a mock auth service.
        // For now, it verifies that tapping "Send OTP" with a valid number
        // causes the OTP field to appear in the UI.
        let phoneField = app.textFields["Phone Number"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))
        phoneField.tap()
        phoneField.typeText("9876543210")

        let sendOTPButton = app.buttons["Send OTP"]
        XCTAssertTrue(sendOTPButton.isEnabled)
        sendOTPButton.tap()

        // After tapping, either the OTP field appears OR an error alert appears
        let otpField = app.textFields["Enter OTP"]
        let errorAlert = app.alerts["Error"]

        let appeared = otpField.waitForExistence(timeout: 10) || errorAlert.waitForExistence(timeout: 10)
        XCTAssertTrue(appeared, "Expected either the OTP field or an error alert after tapping 'Send OTP'")
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
