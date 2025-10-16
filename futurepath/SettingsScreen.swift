//
//  SettingsScreen.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// Settings screen: appearance, behavior, language, and data utilities.
struct SettingsScreen: View {

    // MARK: - ViewModel

    @StateObject private var vm: SettingsViewModel

    // MARK: - Environment

    @EnvironmentObject private var theme: AppTheme
    private let haptics = HapticsManager.shared

    // MARK: - Init

    init(viewModel: SettingsViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                behaviorSection
                languageSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
        .tint(theme.accentColor)
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(isOn: Binding(
                get: { vm.isDarkMode },
                set: { newValue in
                    vm.setDarkMode(newValue)
                    if vm.enableHaptics { haptics.selectionChange() }
                }
            )) {
                Label("Dark Mode", systemImage: "moon.fill")
            }

            // Accent color grid
            VStack(alignment: .leading, spacing: 8) {
                Label("Accent Color", systemImage: "paintpalette.fill")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(vm.accentOptions, id: \.self) { id in
                        AccentSwatch(
                            color: colorForAccentID(id),
                            selected: vm.accentColorID == id,
                            title: readableColorID(id)
                        ) {
                            vm.setAccent(id: id)
                            if vm.enableHaptics { haptics.selectionChange() }
                        }
                    }
                }
                .padding(.top, 2)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle(isOn: Binding(
                get: { vm.enableHaptics },
                set: { newValue in
                    vm.setHapticsEnabled(newValue)
                    if newValue { haptics.selectionChange() }
                }
            )) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }

            Toggle(isOn: Binding(
                get: { vm.autoCarryTasks },
                set: { newValue in
                    vm.setAutoCarry(newValue)
                    if vm.enableHaptics { haptics.selectionChange() }
                }
            )) {
                Label("Auto-carry overdue tasks", systemImage: "arrowshape.turn.up.right")
            }
        }
    }

    private var languageSection: some View {
        Section("Language") {
            Picker("App Language", selection: Binding(
                get: { vm.languageCode },
                set: { vm.setLanguage($0) }
            )) {
                Text("English").tag("en")
            }
            .pickerStyle(.menu)

            Text("Future: Next Path currently supports English.")
                .font(Typography.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                vm.resetToDefaults()
                if vm.enableHaptics { haptics.warning() }
            } label: {
                Label("Reset settings to defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Future: Next Path")
                        .font(Typography.bodyMedium)
                    Text("Personal mood-based planning for iPhone.")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)

            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func colorForAccentID(_ id: String) -> Color {
        switch id {
        case "brandBlue":   return ColorPalette.brandBlue
        case "brandGreen":  return ColorPalette.brandGreen
        case "brandYellow": return ColorPalette.brandYellow
        case "brandCoral":  return ColorPalette.brandCoral
        case "brandPurple": return ColorPalette.brandPurple
        default:            return ColorPalette.brandBlue
        }
    }

    private func readableColorID(_ id: String) -> String {
        switch id {
        case "brandBlue":   return "Blue"
        case "brandGreen":  return "Green"
        case "brandYellow": return "Yellow"
        case "brandCoral":  return "Coral"
        case "brandPurple": return "Purple"
        default:            return id
        }
    }

    private func appVersionString() -> String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(v) (\(b))"
    }
}

// MARK: - Local components

private struct AccentSwatch: View {
    let color: Color
    let selected: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(selected ? Color.primary.opacity(0.35) : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: selected ? "checkmark" : "")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            Text(title)
                .font(Typography.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        let theme = AppTheme()
        let settings = SettingsStore()
        SettingsScreen(viewModel: SettingsViewModel(settings: settings, theme: theme))
            .environmentObject(theme)
            .environmentObject(settings)
    }
}
#endif
