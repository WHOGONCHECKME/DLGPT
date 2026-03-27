import SwiftUI

struct HomeView: View {
    @Binding var showMenu: Bool

    var body: some View {
        ContentView()
            .navigationTitle("DLGPT")
    }
}

#Preview {
    HomeView(showMenu: .constant(false))
}
