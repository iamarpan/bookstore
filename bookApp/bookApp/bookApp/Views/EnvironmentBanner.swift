import SwiftUI

/// Visual banner shown in non-production environments
struct EnvironmentBanner: View {
    let environment: APIEnvironment
    
    var body: some View {
        #if DEBUG
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(environment.displayName.uppercased())
                .font(.caption)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("DEV MODE")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(bannerColor)
        #endif
    }
    
    private var bannerColor: Color {
        switch environment {
        case .development:
            return .orange
        case .staging:
            return .yellow
        case .production:
            return .green
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        EnvironmentBanner(environment: .development)
        EnvironmentBanner(environment: .staging)
        EnvironmentBanner(environment: .production)
    }
}
