import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)

            Text("Settings screen placeholder")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
