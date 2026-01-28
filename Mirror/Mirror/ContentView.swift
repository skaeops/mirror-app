import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home, discover
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                DiscoverView()
                    .tag(Tab.discover)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @State private var showImportSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: "house.fill",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            Spacer()
            
            // Add Button (center)
            Button {
                showImportSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.mirrorYellow)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .offset(y: -16)
            .sheet(isPresented: $showImportSheet) {
                ImportSheet()
            }
            
            Spacer()
            
            // Discover Tab
            TabBarButton(
                icon: "sparkles",
                isSelected: selectedTab == .discover
            ) {
                selectedTab = .discover
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .white : .gray)
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let mirrorYellow = Color(red: 245/255, green: 213/255, blue: 71/255)
    static let mirrorBlue = Color(red: 74/255, green: 158/255, blue: 255/255)
    static let mirrorRed = Color(red: 255/255, green: 107/255, blue: 107/255)
    static let backgroundPrimary = Color.black
    static let backgroundSecondary = Color(white: 0.04)
    static let backgroundTertiary = Color(white: 0.1)
}

#Preview {
    ContentView()
}
