import SwiftUI

struct SettingsView: View {
    @State private var settings = StorageService.shared.readSettings()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Done") {
                    StorageService.shared.updateSettings { s in
                        s = settings
                    }
                    dismiss()
                }
                .sbButton(.blue)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    timerSection
                    behaviorSection
                    appsSection
                    aboutSection
                }
                .padding(16)
            }
        }
        .frame(width: 360, height: 400)
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Timer")

            settingRow("Pomodoro Work") {
                Picker("", selection: $settings.pomodoroWorkMinutes) {
                    ForEach([15, 20, 25, 30, 35, 40, 45, 50], id: \.self) { v in
                        Text("\(v) min").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            settingRow("Pomodoro Break") {
                Picker("", selection: $settings.pomodoroBreakMinutes) {
                    ForEach([3, 5, 7, 10, 15], id: \.self) { v in
                        Text("\(v) min").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            settingRow("Deep Work") {
                Picker("", selection: $settings.deepWorkMinutes) {
                    ForEach([60, 75, 90, 105, 120], id: \.self) { v in
                        Text("\(v) min").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            settingRow("Deep Work Break") {
                Picker("", selection: $settings.deepWorkBreakMinutes) {
                    ForEach([10, 15, 20, 30], id: \.self) { v in
                        Text("\(v) min").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Behavior")

            Toggle("Sound Effects", isOn: $settings.soundEnabled)
                .font(.system(size: 12))
            Toggle("Auto-start Breaks", isOn: $settings.autoStartBreaks)
                .font(.system(size: 12))
            Toggle("Break Reminders", isOn: $settings.enableBreakReminders)
                .font(.system(size: 12))
            Toggle("Notifications", isOn: $settings.notificationsEnabled)
                .font(.system(size: 12))

            settingRow("Daily Goal") {
                Picker("", selection: $settings.dailyGoalHours) {
                    ForEach(Array(stride(from: 1.0, through: 12.0, by: 0.5)), id: \.self) { v in
                        Text("\(v, specifier: "%.1f")h").tag(v)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }
        }
    }

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Distracting Apps")

            Text("These apps are counted as distractions")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)

            ForEach($settings.distractingApps, id: \.self) { $app in
                TextField("App name", text: $app)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("About")
            Text("StudyBar v1.0")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Your student command center")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func settingRow<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
            Spacer()
            content()
        }
    }
}
