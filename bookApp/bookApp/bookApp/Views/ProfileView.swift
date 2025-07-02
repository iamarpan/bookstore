import SwiftUI

struct ProfileView: View {
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(User.mockUser.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Flat: \(User.mockUser.flatNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(User.mockUser.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Library Stats") {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Books Added")
                        Spacer()
                        Text("2")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Books Borrowed")
                        Spacer()
                        Text("2")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("Books Lent")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Text("Pending Requests")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Settings") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Text("Dark Mode")
                        Spacer()
                        Toggle("", isOn: .constant(false))
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Help & Support")
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        Text("Rate App")
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Contact Us")
                    }
                }
                
                Section {
                    Button(action: {
                        // Sign out functionality removed
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("About App")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
} 