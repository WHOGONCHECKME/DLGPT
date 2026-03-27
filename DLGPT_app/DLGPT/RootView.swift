import SwiftUI

struct RootView: View {
    enum MenuItem {
        case home
        case x
        case settings
    }

    @State private var showMenu = false
    @State private var selectedMenu: MenuItem = .home

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                Group {
                    switch selectedMenu {
                    case .home:
                        HomeView(showMenu: $showMenu)
                    case .x:
                        XView()
                    case .settings:
                        SettingsView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showMenu.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
            }

            if showMenu {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMenu = false
                    }

                SideMenuView(selectedMenu: $selectedMenu, showMenu: $showMenu)
                    .frame(width: 260)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showMenu)
    }
}

#Preview {
    RootView()
}
