import SwiftUI

struct PublicProfileView: View {
    let userId: String
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager

    init(userId: String) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: userId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if let profile = viewModel.profile {
                profileContent(profile: profile)
            }
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Main Profile Content

    @ViewBuilder
    private func profileContent(profile: PublicUserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Card
                profileHeader(profile: profile)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                Divider()
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)

                // Stats Section
                statsSection(stats: profile.stats)
                    .padding(.horizontal, 20)

                // Books Section
                if !viewModel.books.isEmpty {
                    booksSection
                        .padding(.top, 24)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func profileHeader(profile: PublicUserProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.12))
                    .frame(width: 88, height: 88)

                if let urlString = profile.profileImageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(profile.initials)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                } else {
                    Text(profile.initials)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }

            // Name & member since
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(AppTheme.headerFont(size: 22))
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)

                Text(profile.memberSince)
                    .font(AppTheme.bodyFont(size: 13))
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            }

            // Bio (if present)
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(AppTheme.bodyFont(size: 15))
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private func statsSection(stats: PublicUserProfile.PublicUserStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(AppTheme.headerFont(size: 17))
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

            HStack(spacing: 12) {
                statCard(
                    icon: "books.vertical.fill",
                    iconColor: AppTheme.primaryAccent,
                    value: "\(stats.booksShared)",
                    label: "Books Shared"
                )
                statCard(
                    icon: "arrow.left.arrow.right.circle.fill",
                    iconColor: AppTheme.successColor,
                    value: "\(stats.successfulLends)",
                    label: "Successful Lends"
                )
                statCard(
                    icon: "star.fill",
                    iconColor: .orange,
                    value: stats.averageRating > 0
                        ? String(format: "%.1f", stats.averageRating)
                        : "—",
                    label: "Avg Rating"
                )
            }
        }
    }

    @ViewBuilder
    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

            Text(label)
                .font(AppTheme.bodyFont(size: 11))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(AppTheme.inputRadius)
        .shadow(color: AppTheme.shadowCard, radius: 4, x: 0, y: 2)
    }

    // MARK: - Books Section

    @ViewBuilder
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Listed Books")
                .font(AppTheme.headerFont(size: 17))
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(viewModel.books) { book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        PublicProfileBookCard(book: book, isDarkMode: themeManager.isDarkMode)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Loading / Error States

    private var loadingView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Avatar + name skeleton
                VStack(spacing: 16) {
                    ShimmerView(isDarkMode: themeManager.isDarkMode)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())

                    VStack(spacing: 8) {
                        ShimmerView(isDarkMode: themeManager.isDarkMode)
                            .frame(width: 160, height: 20)
                            .cornerRadius(6)
                        ShimmerView(isDarkMode: themeManager.isDarkMode)
                            .frame(width: 120, height: 14)
                            .cornerRadius(5)
                    }

                    // Bio lines
                    VStack(spacing: 6) {
                        ShimmerView(isDarkMode: themeManager.isDarkMode)
                            .frame(maxWidth: .infinity)
                            .frame(height: 13)
                            .cornerRadius(5)
                        ShimmerView(isDarkMode: themeManager.isDarkMode)
                            .frame(width: 220, height: 13)
                            .cornerRadius(5)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Divider()
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)

                // Stats skeleton
                VStack(alignment: .leading, spacing: 12) {
                    ShimmerView(isDarkMode: themeManager.isDarkMode)
                        .frame(width: 80, height: 18)
                        .cornerRadius(5)

                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView(isDarkMode: themeManager.isDarkMode)
                                .frame(maxWidth: .infinity)
                                .frame(height: 88)
                                .cornerRadius(AppTheme.inputRadius)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Books grid skeleton
                VStack(alignment: .leading, spacing: 12) {
                    ShimmerView(isDarkMode: themeManager.isDarkMode)
                        .frame(width: 110, height: 18)
                        .cornerRadius(5)
                        .padding(.top, 24)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(0..<4, id: \.self) { _ in
                            ShimmerView(isDarkMode: themeManager.isDarkMode)
                                .frame(height: 200)
                                .cornerRadius(AppTheme.inputRadius)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            Text(message)
                .font(AppTheme.bodyFont(size: 16))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Mini Book Card for Profile Grid

struct PublicProfileBookCard: View {
    let book: Book
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            AsyncImage(url: URL(string: book.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Title
            Text(book.title)
                .font(AppTheme.bodyFont(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Availability badge
            HStack(spacing: 4) {
                Circle()
                    .fill(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
                    .frame(width: 6, height: 6)
                Text(book.isAvailable ? "Available" : "Borrowed")
                    .font(AppTheme.bodyFont(size: 11))
                    .foregroundColor(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
            }
        }
        .padding(10)
        .background(AppTheme.colorCardBackground(for: isDarkMode))
        .cornerRadius(AppTheme.inputRadius)
        .shadow(color: AppTheme.shadowCard, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Shimmer View (animated skeleton placeholder)

struct ShimmerView: View {
    let isDarkMode: Bool
    @State private var phase: CGFloat = -1.0

    private var baseColor: Color {
        isDarkMode ? Color(white: 0.18) : Color(white: 0.88)
    }
    private var highlightColor: Color {
        isDarkMode ? Color(white: 0.28) : Color(white: 0.96)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: baseColor, location: 0),
                    .init(color: baseColor, location: max(0, phase - 0.3)),
                    .init(color: highlightColor, location: phase),
                    .init(color: baseColor, location: min(1, phase + 0.3)),
                    .init(color: baseColor, location: 1),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 3)
            .offset(x: width * phase * 2 - width)
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}
