import SwiftUI

struct SideMenuView: View {
    @Binding var selectedMenu: RootView.MenuItem
    @Binding var showMenu: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Menu")
                .font(.title2)
                .bold()

            Button("Home") {
                selectedMenu = .home
                showMenu = false
            }

            Button("X") {
                selectedMenu = .x
                showMenu = false
            }

            Button("Settings") {
                selectedMenu = .settings
                showMenu = false
            }

            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
}

#Preview {
    SideMenuView(
        selectedMenu: .constant(.home),
        showMenu: .constant(true)
    )
}
