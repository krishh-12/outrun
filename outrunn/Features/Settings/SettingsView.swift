//
//  SettingsView.swift
//  outrunn
//

import SwiftUI

struct SettingsView: View {
    @Bindable var state: UserRecoveryState
    var onLogOut: () -> Void

    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var ageText: String = ""
    @State private var showLogOutConfirm = false
    @State private var saveMessage: String?
    @State private var showResetConfirm = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case age
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Neu.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        sectionTitle("Profile")

                        VStack(alignment: .leading, spacing: 14) {
                            labeledField("Name", text: $name, field: .name)
                            labeledField("Chronological Age", text: $ageText, field: .age)
                                .keyboardType(.decimalPad)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(Neu.label(13))
                                    .foregroundStyle(Neu.muted)
                                Text(auth.currentUser?.email ?? state.profileEmail ?? "Not set")
                                    .font(Neu.body(16))
                                    .foregroundStyle(Neu.ink)
                            }
                        }
                        .padding(16)
                        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))

                        Button {
                            saveProfile()
                        } label: {
                            Text(saveMessage ?? "Save Profile")
                                .font(Neu.button(17))
                                .foregroundStyle(Neu.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(NeuButtonStyle())

                        sectionTitle("System")

                        VStack(spacing: 0) {
                            toggleRow("Haptics", isOn: hapticsBinding)
                            Divider().opacity(0.15)
                            infoRow("Scans Stored", value: "\(state.scanHistory.count)")
                            Divider().opacity(0.15)
                            infoRow("Age Readings", value: "\(state.ageHistory.count)")
                            Divider().opacity(0.15)
                            infoRow("Devices", value: "\(state.connectedIntegrations.count) connected")
                        }
                        .padding(16)
                        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))

                        sectionTitle("Data")

                        Button {
                            showResetConfirm = true
                        } label: {
                            Text("Reset Data")
                                .font(Neu.button(17))
                                .foregroundStyle(Neu.older)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(NeuButtonStyle())

                        Button {
                            showLogOutConfirm = true
                        } label: {
                            Text("Log Out")
                                .font(Neu.button(17))
                                .foregroundStyle(Neu.older)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(NeuButtonStyle())
                    }
                    .padding(22)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Reset Data", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Today", role: .destructive) {
                    state.resetData(.day)
                }
                Button("Reset This Week", role: .destructive) {
                    state.resetData(.week)
                }
                Button("Reset All Time", role: .destructive) {
                    state.resetData(.all)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes scans and age readings for the selected period. Profile and linked devices stay.")
            }
            .confirmationDialog("Log out of outrunn?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    dismiss()
                    onLogOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                name = state.userName
                ageText = String(format: "%.0f", state.chronologicalAge)
            }
        }
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { state.hapticsEnabled },
            set: {
                state.hapticsEnabled = $0
                state.persistSoon()
            }
        )
    }

    private func saveProfile() {
        focusedField = nil
        if state.persistenceKey == nil || state.persistenceKey?.isEmpty == true {
            state.persistenceKey = auth.currentUser?.id ?? "local"
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAge = Double(ageText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
            ?? state.chronologicalAge
        state.updateProfile(
            name: trimmedName.isEmpty ? state.userName : trimmedName,
            chronologicalAge: min(90, max(16, parsedAge)),
            email: auth.currentUser?.email ?? state.profileEmail
        )
        name = state.userName
        ageText = String(format: "%.0f", state.chronologicalAge)
        saveMessage = "Saved"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if saveMessage == "Saved" {
                saveMessage = nil
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Neu.display(22))
            .italic()
            .foregroundStyle(Neu.ink)
    }

    private func labeledField(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Neu.label(13))
                .foregroundStyle(Neu.muted)
            NeuField(placeholder: title, text: text)
                .focused($focusedField, equals: field)
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(Neu.body(16))
                .foregroundStyle(Neu.ink)
        }
        .tint(Neu.accent)
        .padding(.vertical, 8)
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Neu.body(16))
                .foregroundStyle(Neu.ink)
            Spacer()
            Text(value)
                .font(Neu.body(15))
                .foregroundStyle(Neu.muted)
        }
        .padding(.vertical, 10)
    }
}
