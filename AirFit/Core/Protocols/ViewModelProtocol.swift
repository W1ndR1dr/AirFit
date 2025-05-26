import Foundation
import SwiftUI

/// Base protocol for all ViewModels in the app
@MainActor
protocol ViewModelProtocol: AnyObject, Observable {
    /// The current loading state of the view model
    var loadingState: LoadingState { get }

    /// Initialize the view model and load initial data if needed
    func initialize() async

    /// Refresh the data
    func refresh() async

    /// Clean up resources when the view model is no longer needed
    func cleanup()
}

/// Extension providing default implementations
extension ViewModelProtocol {
    /// Default implementation does nothing
    func initialize() async {}

    /// Default implementation does nothing
    func refresh() async {}

    /// Default implementation does nothing
    func cleanup() {}
}

/// Protocol for ViewModels that handle form validation
@MainActor
protocol FormViewModelProtocol: ViewModelProtocol {
    associatedtype FormData

    /// The current form data
    var formData: FormData { get set }

    /// Whether the form is currently valid
    var isFormValid: Bool { get }

    /// Validate the form and return any errors
    func validate() -> [String: String]

    /// Submit the form
    func submit() async throws
}

/// Protocol for ViewModels that handle list data
@MainActor
protocol ListViewModelProtocol: ViewModelProtocol {
    associatedtype Item: Identifiable

    /// The list items
    var items: [Item] { get }

    /// Whether there are more items to load
    var hasMoreItems: Bool { get }

    /// The current search query
    var searchQuery: String { get set }

    /// Load more items (for pagination)
    func loadMore() async

    /// Delete an item at the specified offsets
    func delete(at offsets: IndexSet) async throws
}

/// Protocol for ViewModels that handle detail views
@MainActor
protocol DetailViewModelProtocol: ViewModelProtocol {
    associatedtype Model

    /// The detail model
    var model: Model? { get }

    /// Load the detail data
    func load(id: String) async throws

    /// Save changes to the model
    func save() async throws

    /// Delete the model
    func delete() async throws
}
