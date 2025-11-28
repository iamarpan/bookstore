import SwiftUI
import Combine

class TabManager: ObservableObject {
    @Published var isVisible: Bool = true
    
    func show() {
        withAnimation {
            isVisible = true
        }
    }
    
    func hide() {
        withAnimation {
            isVisible = false
        }
    }
}
