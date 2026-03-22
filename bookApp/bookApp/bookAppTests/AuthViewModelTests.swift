// bookAppTests/AuthViewModelTests.swift
// Unit tests for AuthViewModel — validation logic, state transitions, and error handling.

import Testing
@testable import bookApp

// MARK: - AuthViewModel Tests

@MainActor
struct AuthViewModelTests {

    // MARK: - isPhoneValid

    @Test("Phone number shorter than 10 digits is invalid")
    func phoneValidation_tooShort_isInvalid() {
        let vm = AuthViewModel()
        vm.phoneNumber = "12345"
        #expect(vm.isPhoneValid == false)
    }

    @Test("Phone number exactly 10 digits is valid")
    func phoneValidation_tenDigits_isValid() {
        let vm = AuthViewModel()
        vm.phoneNumber = "9876543210"
        #expect(vm.isPhoneValid == true)
    }

    @Test("Phone number longer than 10 digits is valid")
    func phoneValidation_longNumber_isValid() {
        let vm = AuthViewModel()
        vm.phoneNumber = "+919876543210"
        #expect(vm.isPhoneValid == true)
    }

    @Test("Empty phone number is invalid")
    func phoneValidation_empty_isInvalid() {
        let vm = AuthViewModel()
        vm.phoneNumber = ""
        #expect(vm.isPhoneValid == false)
    }

    // MARK: - isOTPValid

    @Test("4-digit OTP is valid")
    func otpValidation_fourDigits_isValid() {
        let vm = AuthViewModel()
        vm.otp = "1234"
        #expect(vm.isOTPValid == true)
    }

    @Test("6-digit OTP is valid")
    func otpValidation_sixDigits_isValid() {
        let vm = AuthViewModel()
        vm.otp = "123456"
        #expect(vm.isOTPValid == true)
    }

    @Test("5-digit OTP is invalid")
    func otpValidation_fiveDigits_isInvalid() {
        let vm = AuthViewModel()
        vm.otp = "12345"
        #expect(vm.isOTPValid == false)
    }

    @Test("Empty OTP is invalid")
    func otpValidation_empty_isInvalid() {
        let vm = AuthViewModel()
        vm.otp = ""
        #expect(vm.isOTPValid == false)
    }

    // MARK: - isRegistrationValid

    @Test("Registration invalid when name is empty")
    func registrationValidation_emptyName_isInvalid() {
        let vm = AuthViewModel()
        vm.name = ""
        vm.phoneNumber = "9876543210"
        #expect(vm.isRegistrationValid == false)
    }

    @Test("Registration invalid when phone is too short")
    func registrationValidation_invalidPhone_isInvalid() {
        let vm = AuthViewModel()
        vm.name = "John Doe"
        vm.phoneNumber = "123"
        #expect(vm.isRegistrationValid == false)
    }

    @Test("Registration valid with name and valid phone")
    func registrationValidation_valid() {
        let vm = AuthViewModel()
        vm.name = "John Doe"
        vm.phoneNumber = "9876543210"
        #expect(vm.isRegistrationValid == true)
    }

    // MARK: - sendOTP — success case

    @Test("sendOTP with valid phone calls service and sets no error")
    @MainActor func sendOTP_validPhone_success() async {
        let mockService = MockAuthService()
        let vm = AuthViewModel(authService: mockService)
        vm.phoneNumber = "9876543210"
        
        await vm.sendOTP()
        
        #expect(mockService.otpSentSuccessfully == true)
        #expect(vm.showError == false)
    }

    // MARK: - sendOTP — guard: invalid phone

    @Test("sendOTP with invalid phone sets showError and errorMessage")
    @MainActor func sendOTP_invalidPhone_setsError() async {
        let mockService = MockAuthService()
        let vm = AuthViewModel(authService: mockService)
        vm.phoneNumber = "123" // too short
        await vm.sendOTP()
        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - verifyOTP — success case

    @Test("verifyOTP with valid OTP succeeds")
    @MainActor func verifyOTP_success() async {
        let mockService = MockAuthService()
        let vm = AuthViewModel(authService: mockService)
        vm.phoneNumber = "9876543210"
        vm.otp = "123456"
        
        await vm.verifyOTP()
        
        #expect(mockService.verifyOTPSuccessful == true)
        #expect(vm.showRegistrationForm == false)
        #expect(vm.showError == false)
    }

    @Test("verifyOTP for new user shows registration form")
    @MainActor func verifyOTP_newUser_showsRegistration() async {
        let mockService = MockAuthService()
        mockService.needsRegistration = true
        let vm = AuthViewModel(authService: mockService)
        vm.phoneNumber = "9876543210"
        vm.otp = "123456"
        
        await vm.verifyOTP()
        
        #expect(vm.showRegistrationForm == true)
        #expect(vm.needsRegistration == true)
        #expect(vm.showError == false)
    }

    // MARK: - verifyOTP — guard: invalid OTP

    @Test("verifyOTP with invalid OTP sets showError and errorMessage")
    @MainActor func verifyOTP_invalidOTP_setsError() async {
        let mockService = MockAuthService()
        let vm = AuthViewModel(authService: mockService)
        vm.otp = "12" // invalid
        await vm.verifyOTP()
        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - resetForm

    @Test("resetForm clears all input fields and error state")
    @MainActor func resetForm_clearsAllFields() {
        let mockService = MockAuthService()
        let vm = AuthViewModel(authService: mockService)
        vm.phoneNumber = "9876543210"
        vm.otp = "1234"
        vm.name = "Jane"
        vm.bio = "A reader"
        vm.errorMessage = "Some error"
        vm.showError = true

        vm.resetForm()

        #expect(vm.phoneNumber.isEmpty)
        #expect(vm.otp.isEmpty)
        #expect(vm.name.isEmpty)
        #expect(vm.bio.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.showError == false)
    }

    // MARK: - validatePhoneNumber (helper)

    @Test("validatePhoneNumber accepts valid 10-digit number")
    @MainActor func validatePhoneNumber_tenDigits_isValid() {
        let vm = AuthViewModel()
        #expect(vm.validatePhoneNumber("9876543210") == true)
    }

    @Test("validatePhoneNumber accepts E.164 international format")
    @MainActor func validatePhoneNumber_e164_isValid() {
        let vm = AuthViewModel()
        #expect(vm.validatePhoneNumber("+919876543210") == true)
    }

    @Test("validatePhoneNumber rejects alphabetic strings")
    @MainActor func validatePhoneNumber_alpha_isInvalid() {
        let vm = AuthViewModel()
        #expect(vm.validatePhoneNumber("abcdefghij") == false)
    }
}

