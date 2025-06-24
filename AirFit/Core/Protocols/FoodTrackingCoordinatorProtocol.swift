import SwiftUI

/// Protocol for food tracking navigation coordination
@MainActor
public protocol FoodTrackingCoordinatorProtocol: AnyObject {
    associatedtype SheetType: Identifiable
    associatedtype CoverType: Identifiable
    
    var activeSheet: SheetType? { get set }
    var activeFullScreenCover: CoverType? { get set }
    
    func showSheet(_ sheet: SheetType)
    func showFullScreenCover(_ cover: CoverType)
    func dismiss()
}

/// Default implementation
extension FoodTrackingCoordinatorProtocol {
    func dismiss() {
        activeSheet = nil
        activeFullScreenCover = nil
    }
}
