import SwiftUI

/// # BaseCoordinator
/// 
/// ## Purpose
/// Provides a complete base implementation for all coordinators, handling navigation,
/// sheets, and alerts in a consistent, type-safe way.
///
/// ## Usage Example
/// ```swift
/// @Observable
/// final class DashboardCoordinator: BaseCoordinator<DashboardDestination, DashboardSheet, DashboardAlert> {
///     // That's it! You get navigation, sheet, and alert handling for free
/// }
/// ```
///
/// ## For Simple Cases
/// If you don't need sheets or alerts, use convenience types:
/// ```swift
/// class MyCoordinator: SimpleCoordinator<MyDestination> // No sheets/alerts
/// class MyCoordinator: SheetCoordinator<MyDestination, MySheet> // No alerts
/// ```
///
/// ## What You Get
/// - `navigationPath` - The navigation stack
/// - `activeSheet` - Current sheet being presented
/// - `activeAlert` - Current alert being shown
/// - `navigateTo(_:)` - Push to navigation stack
/// - `pop()` - Go back one screen
/// - `popToRoot()` - Go to root screen
/// - `showSheet(_:)` - Present a sheet
/// - `showAlert(_:)` - Show an alert
/// - `dismiss()` - Dismiss any sheet/alert

// MARK: - Base Protocol

@MainActor
protocol CoordinatorProtocol: AnyObject {
    associatedtype Destination: Hashable
    associatedtype Sheet: Identifiable
    associatedtype Alert: Identifiable
    
    var navigationPath: NavigationPath { get set }
    var activeSheet: Sheet? { get set }
    var activeAlert: Alert? { get set }
}

// MARK: - Base Implementation

@MainActor
@Observable
class BaseCoordinator<Destination: Hashable, Sheet: Identifiable, Alert: Identifiable>: CoordinatorProtocol {
    var navigationPath = NavigationPath()
    var activeSheet: Sheet?
    var activeAlert: Alert?
    
    // Navigation
    func navigateTo(_ destination: Destination) {
        navigationPath.append(destination)
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    func popToRoot() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast(navigationPath.count)
    }
    
    // Presentation
    func showSheet(_ sheet: Sheet) {
        activeSheet = sheet
    }
    
    func showAlert(_ alert: Alert) {
        activeAlert = alert
    }
    
    func dismiss() {
        activeSheet = nil
        activeAlert = nil
    }
    
    // Deep linking
    func handleDeepLink(_ destination: Destination) {
        popToRoot()
        navigateTo(destination)
    }
    
    // Helpers
    var canNavigateBack: Bool { !navigationPath.isEmpty }
    
    // Compatibility
    var path: NavigationPath {
        get { navigationPath }
        set { navigationPath = newValue }
    }
}

// MARK: - Convenience Types

/// For coordinators that don't need sheets or alerts
typealias SimpleCoordinator<Destination: Hashable> = BaseCoordinator<Destination, Never, Never>

/// For coordinators that need sheets but not alerts  
typealias SheetCoordinator<Destination: Hashable, Sheet: Identifiable> = BaseCoordinator<Destination, Sheet, Never>

// MARK: - Empty Types for Unused Features

// Never is already Identifiable in Swift - extension removed to avoid redundancy