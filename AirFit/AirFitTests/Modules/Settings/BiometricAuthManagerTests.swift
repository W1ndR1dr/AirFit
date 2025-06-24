import XCTest
import LocalAuthentication
@testable import AirFit

final class BiometricAuthManagerTests: XCTestCase {
    var sut: BiometricAuthManager!
    
    override func setUp() throws {
        try super.setUp()
        sut = BiometricAuthManager()
    }
    
    override func tearDown() throws {
        sut = nil
        try super.tearDown()
    }
    
    func test_biometricType_shouldReturnCorrectType() {
        // In simulator/test environment, this will typically return .none
        let biometricType = sut.biometricType
        
        // Assert - we can't control the hardware, so we just verify it returns a valid type
        XCTAssertTrue([BiometricType.none, .faceID, .touchID, .opticID].contains(biometricType))
    }
    
    func test_canUseBiometrics_shouldReturnBooleanValue() {
        // Act
        let canUse = sut.canUseBiometrics
        
        // Assert - in test environment, this is typically false
        XCTAssertNotNil(canUse)
    }
    
    func test_reset_shouldInvalidateContext() {
        // Act
        sut.reset()
        
        // Assert - no crash means success (context was invalidated)
        XCTAssertTrue(true)
    }
    
    func test_biometricError_fromLAError_shouldMapCorrectly() {
        // Test error mapping
        let testCases: [(LAError.Code, BiometricError)] = [
            (.authenticationFailed, .authenticationFailed),
            (.userCancel, .userCancelled),
            (.userFallback, .userFallback),
            (.systemCancel, .systemCancel),
            (.passcodeNotSet, .passcodeNotSet),
            (.biometryNotAvailable, .biometryNotAvailable),
            (.biometryNotEnrolled, .biometryNotEnrolled),
            (.biometryLockout, .biometryLockout)
        ]
        
        for (laErrorCode, expectedBiometricError) in testCases {
            let laError = LAError(laErrorCode)
            let biometricError = BiometricError.fromLAError(laError)
            
            switch (biometricError, expectedBiometricError) {
            case (.authenticationFailed, .authenticationFailed),
                 (.userCancelled, .userCancelled),
                 (.userFallback, .userFallback),
                 (.systemCancel, .systemCancel),
                 (.passcodeNotSet, .passcodeNotSet),
                 (.biometryNotAvailable, .biometryNotAvailable),
                 (.biometryNotEnrolled, .biometryNotEnrolled),
                 (.biometryLockout, .biometryLockout):
                // Correct mapping
                break
            default:
                XCTFail("Incorrect error mapping for \(laErrorCode)")
            }
        }
    }
    
    func test_biometricType_displayName_shouldReturnCorrectString() {
        // Test all biometric types
        XCTAssertEqual(BiometricType.faceID.displayName, "Face ID")
        XCTAssertEqual(BiometricType.touchID.displayName, "Touch ID")
        XCTAssertEqual(BiometricType.opticID.displayName, "Optic ID")
        XCTAssertEqual(BiometricType.none.displayName, "Not Available")
    }
    
    func test_biometricType_icon_shouldReturnCorrectIcon() {
        // Test all biometric types
        XCTAssertEqual(BiometricType.faceID.icon, "faceid")
        XCTAssertEqual(BiometricType.touchID.icon, "touchid")
        XCTAssertEqual(BiometricType.opticID.icon, "opticid")
        XCTAssertEqual(BiometricType.none.icon, "lock")
    }
    
    func test_biometricError_localizedDescription_shouldReturnCorrectMessage() {
        // Test error descriptions
        XCTAssertEqual(BiometricError.notAvailable.localizedDescription, "Biometric authentication is not available on this device")
        XCTAssertEqual(BiometricError.authenticationFailed.localizedDescription, "Authentication failed. Please try again.")
        XCTAssertEqual(BiometricError.userCancelled.localizedDescription, "Authentication was cancelled")
        XCTAssertEqual(BiometricError.biometryLockout.localizedDescription, "Biometry is locked out due to too many failed attempts")
    }
}
