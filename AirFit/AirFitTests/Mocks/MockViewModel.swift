import Foundation
import SwiftUI
@testable import AirFit

// MARK: - MockViewModel (Generic ViewModelProtocol Implementation)
@MainActor
final class MockViewModel: ViewModelProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // ViewModelProtocol conformance
    @Published var loadingState: LoadingState = .idle
    
    // Stubbed behaviors
    var stubbedInitializeError: Error?
    var stubbedRefreshError: Error?
    var shouldDelayInitialize: Bool = false
    var shouldDelayRefresh: Bool = false
    var initializeDelay: TimeInterval = 0.5
    var refreshDelay: TimeInterval = 0.5
    
    func initialize() async {
        recordInvocation("initialize", arguments: nil)
        loadingState = .loading
        
        if shouldDelayInitialize {
            try? await Task.sleep(nanoseconds: UInt64(initializeDelay * 1_000_000_000))
        }
        
        if let error = stubbedInitializeError {
            loadingState = .error(error)
            return
        }
        
        loadingState = .loaded
    }
    
    func refresh() async {
        recordInvocation("refresh", arguments: nil)
        loadingState = .refreshing
        
        if shouldDelayRefresh {
            try? await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
        }
        
        if let error = stubbedRefreshError {
            loadingState = .error(error)
            return
        }
        
        loadingState = .loaded
    }
    
    func cleanup() {
        recordInvocation("cleanup", arguments: nil)
        loadingState = .idle
    }
    
    // Helper methods for testing
    func stubInitializeError(with error: Error) {
        stubbedInitializeError = error
    }
    
    func stubRefreshError(with error: Error) {
        stubbedRefreshError = error
    }
    
    func stubLoadingState(_ state: LoadingState) {
        loadingState = state
    }
    
    func stubDelayInitialize(for duration: TimeInterval) {
        shouldDelayInitialize = true
        initializeDelay = duration
    }
    
    func stubDelayRefresh(for duration: TimeInterval) {
        shouldDelayRefresh = true
        refreshDelay = duration
    }
    
    // Verify helpers
    func verifyInitialize(called times: Int = 1) {
        verify("initialize", called: times)
    }
    
    func verifyRefresh(called times: Int = 1) {
        verify("refresh", called: times)
    }
    
    func verifyCleanup(called times: Int = 1) {
        verify("cleanup", called: times)
    }
}

// MARK: - MockFormViewModel
@MainActor
final class MockFormViewModel<T>: FormViewModelProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // FormViewModelProtocol conformance
    typealias FormData = T
    
    @Published var loadingState: LoadingState = .idle
    @Published var formData: T
    @Published var isFormValid: Bool = true
    
    // Stubbed behaviors
    var stubbedValidationErrors: [String: String] = [:]
    var stubbedSubmitError: Error?
    var shouldDelaySubmit: Bool = false
    var submitDelay: TimeInterval = 0.5
    
    init(initialFormData: T) {
        self.formData = initialFormData
    }
    
    func initialize() async {
        recordInvocation("initialize", arguments: nil)
    }
    
    func refresh() async {
        recordInvocation("refresh", arguments: nil)
    }
    
    func cleanup() {
        recordInvocation("cleanup", arguments: nil)
    }
    
    func validate() -> [String: String] {
        recordInvocation("validate", arguments: nil)
        isFormValid = stubbedValidationErrors.isEmpty
        return stubbedValidationErrors
    }
    
    func submit() async throws {
        recordInvocation("submit", arguments: nil)
        loadingState = .loading
        
        if shouldDelaySubmit {
            try? await Task.sleep(nanoseconds: UInt64(submitDelay * 1_000_000_000))
        }
        
        if let error = stubbedSubmitError {
            loadingState = .error(error)
            throw error
        }
        
        loadingState = .loaded
    }
    
    // Helper methods
    func stubValidationErrors(_ errors: [String: String]) {
        stubbedValidationErrors = errors
        isFormValid = errors.isEmpty
    }
    
    func stubSubmitError(with error: Error) {
        stubbedSubmitError = error
    }
    
    func stubDelaySubmit(for duration: TimeInterval) {
        shouldDelaySubmit = true
        submitDelay = duration
    }
}

// MARK: - MockListViewModel
@MainActor
final class MockListViewModel<Item: Identifiable>: ListViewModelProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // ListViewModelProtocol conformance
    @Published var loadingState: LoadingState = .idle
    @Published var items: [Item] = []
    @Published var hasMoreItems: Bool = true
    @Published var searchQuery: String = ""
    
    // Stubbed behaviors
    var stubbedLoadMoreError: Error?
    var stubbedDeleteError: Error?
    var additionalItemsToLoad: [Item] = []
    
    func initialize() async {
        recordInvocation("initialize", arguments: nil)
    }
    
    func refresh() async {
        recordInvocation("refresh", arguments: nil)
    }
    
    func cleanup() {
        recordInvocation("cleanup", arguments: nil)
    }
    
    func loadMore() async {
        recordInvocation("loadMore", arguments: nil)
        
        if let error = stubbedLoadMoreError {
            loadingState = .error(error)
            return
        }
        
        items.append(contentsOf: additionalItemsToLoad)
        hasMoreItems = !additionalItemsToLoad.isEmpty
    }
    
    func delete(at offsets: IndexSet) async throws {
        recordInvocation("delete", arguments: offsets)
        
        if let error = stubbedDeleteError {
            throw error
        }
        
        items.remove(atOffsets: offsets)
    }
    
    // Helper methods
    func stubItems(_ items: [Item]) {
        self.items = items
    }
    
    func stubAdditionalItems(_ items: [Item]) {
        additionalItemsToLoad = items
    }
    
    func stubLoadMoreError(with error: Error) {
        stubbedLoadMoreError = error
    }
    
    func stubDeleteError(with error: Error) {
        stubbedDeleteError = error
    }
    
    func stubHasMoreItems(_ hasMore: Bool) {
        hasMoreItems = hasMore
    }
}