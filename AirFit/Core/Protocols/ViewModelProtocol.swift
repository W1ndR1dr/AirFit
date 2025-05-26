import Foundation

/// A basic ViewModel contract for observable models
@MainActor
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    var state: State { get }
}
