import SwiftUI

struct ConditionDotsView: View {
    let condition: BookCondition
    var isDarkMode: Bool = false

    private var filledCount: Int {
        switch condition {
        case .new: return 5
        case .likeNew: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? AppTheme.primaryAccent : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
