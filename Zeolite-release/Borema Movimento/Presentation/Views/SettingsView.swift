import SwiftUI
import UIKit

// MARK: - SettingsView

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showPrivacyPolicy = false
    @State private var showAboutApp = false
    @State private var showEmojiPicker = false

    @State private var userName: String = UserDefaults.standard.string(forKey: "user.name") ?? "User"
    @State private var selectedEmoji: String = UserDefaults.standard.string(forKey: "user.emoji") ?? "😊"

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground(configuration: .darkGold)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

                        header

                        profileCard

                        glassSection(title: "Feedback") {
                            SettingsRow(
                                icon: "speaker.wave.2.fill",
                                title: "Voice Guidance"
                            ) {
                                Picker("", selection: $viewModel.voiceGuidance) {
                                    Text("Off").tag(0)
                                    Text("Quiet").tag(1)
                                    Text("Full").tag(2)
                                }
                                .pickerStyle(.menu)
                                .tint(.yellow)
                                .onChange(of: viewModel.voiceGuidance) { _ in
                                    viewModel.saveSettings()
                                }
                            }

                            Divider().opacity(0.3)

                            SettingsRow(
                                icon: "hand.tap.fill",
                                title: "Haptic Feedback"
                            ) {
                                Toggle("", isOn: $viewModel.hapticsEnabled)
                                    .tint(.yellow)
                                    .onChange(of: viewModel.hapticsEnabled) { _ in
                                        viewModel.saveSettings()
                                    }
                            }
                        }

                        glassSection(title: "About") {
                            navRow("About App") {
                                showAboutApp = true
                            }

                            Divider().opacity(0.3)

                            navRow("Privacy Policy") {
                                showPrivacyPolicy = true
                            }
                        }

                        glassSection(title: "Advanced") {
                            Button {
                                viewModel.showResetConfirmation()
                            } label: {
                                SettingsRow(
                                    icon: "arrow.counterclockwise",
                                    title: "Reset All Data",
                                    iconColor: .red,
                                    titleColor: .red
                                ) {
                                    EmptyView()
                                }
                            }

                            Text("This will delete all progress and settings.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }

                doneButton
            }
            .navigationBarHidden(true)
            .alert("Reset All Data?", isPresented: $viewModel.showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllData()
                    dismiss()
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                InfoSheetView(title: "Privacy Policy", content: privacyPolicyContent)
            }
            .sheet(isPresented: $showAboutApp) {
                InfoSheetView(title: "About App", content: aboutAppContent)
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(
                    selectedEmoji: $selectedEmoji,
                    availableEmojis: ["😊","😎","🤩","😍","🥳","😇","🤗"]
                )
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Header

private extension SettingsView {
    var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Profile Card

private extension SettingsView {
    var profileCard: some View {
        VStack(spacing: 16) {
            Button {
                showEmojiPicker = true
            } label: {
                Text(selectedEmoji)
                    .font(.system(size: 72))
                    .frame(width: 110, height: 110)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.yellow.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .yellow.opacity(0.4), radius: 20)
            }

            CustomTextField(text: $userName, placeholder: "Your Name")
                .frame(height: 54)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.yellow.opacity(0.4), lineWidth: 1)
                )
                .onChange(of: userName) {
                    UserDefaults.standard.set($0, forKey: "user.name")
                }
        }
    }
}

// MARK: - Glass Section + Nav Row

private extension SettingsView {
    func glassSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .foregroundColor(.yellow)
                .font(.headline)

            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.yellow.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .yellow.opacity(0.25), radius: 18)
        }
    }

    func navRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsRow(icon: "chevron.right", title: title) {
                EmptyView()
            }
        }
    }
}

// MARK: - Done Button

private extension SettingsView {
    var doneButton: some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.yellow)
                .font(.system(size: 17, weight: .semibold))
            }
            .padding()
            Spacer()
        }
    }
    
    var privacyPolicyContent: String {
        """
        Privacy Policy
        
        Last Updated: January 2025
        
        Introduction
        
        We respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.
        
        Information We Collect
        
        We may collect the following types of information:
        - Usage data and analytics to improve our services
        - Device information for compatibility purposes
        - User preferences and settings
        
        How We Use Your Information
        
        Your information is used to:
        - Provide and improve our services
        - Personalize your experience
        - Analyze usage patterns
        
        Data Security
        
        We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.
        
        Your Rights
        
        You have the right to access, modify, or delete your personal information at any time through the application settings.
        
        Contact Us
        
        If you have any questions about this Privacy Policy, please contact us through the application support channels.
        """
    }
    
    var aboutAppContent: String {
        """
        About App
        
        Version 1.0.0
        
        Welcome to our application! We are dedicated to providing you with the best possible experience.
        
        Features
        
        Our application offers a comprehensive set of features designed to help you achieve your goals. We continuously work on improving functionality and adding new capabilities based on user feedback.
        
        Technology
        
        Built with modern technologies and best practices, our application ensures a smooth and reliable user experience across all supported devices.
        
        Support
        
        If you encounter any issues or have suggestions for improvement, please don't hesitate to reach out to our support team. We value your feedback and are committed to making our application better for everyone.
        
        Thank you for using our application!
        """
    }
}

// MARK: - SettingsRow

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    var iconColor: Color = .yellow
    var titleColor: Color = .white
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .foregroundColor(titleColor)

            Spacer()

            content
        }
        .padding(.vertical, 10)
    }
}

// MARK: - InfoSheetView

struct InfoSheetView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground(configuration: .darkGold)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        ForEach(parseContent(content), id: \.self) { section in
                            if section.isEmpty {
                                Spacer()
                                    .frame(height: DesignTokens.Spacing.md)
                            } else if isHeader(section) {
                                Text(section)
                                    .font(.system(size: 22, weight: .bold, design: .default))
                                    .foregroundColor(DesignTokens.Colors.accentGold)
                                    .padding(.top, DesignTokens.Spacing.md)
                            } else if section.hasPrefix("- ") {
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                                    Text("•")
                                        .foregroundColor(DesignTokens.Colors.accentGold)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(String(section.dropFirst(2)))
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                }
                                .padding(.leading, DesignTokens.Spacing.md)
                            } else {
                                Text(section)
                                    .foregroundColor(.white.opacity(0.85))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .lineSpacing(6)
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.accentGold)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                }
            }
        }
    }
    
    private func parseContent(_ content: String) -> [String] {
        let lines = content.components(separatedBy: .newlines)
        var sections: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                sections.append(trimmed)
            } else if !sections.isEmpty && !sections.last!.isEmpty {
                sections.append("")
            }
        }
        
        return sections
    }
    
    private func isHeader(_ text: String) -> Bool {
        let headers = ["Privacy Policy", "Last Updated:", "Introduction", "Information We Collect", 
                      "How We Use Your Information", "Data Security", "Your Rights", "Contact Us",
                      "About App", "Version", "Welcome", "Features", "Technology", "Support", "Thank you"]
        return headers.contains { text.contains($0) } && text.count < 50 && !text.hasPrefix("-")
    }
}

// MARK: - Emoji Picker

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let availableEmojis: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            LazyVGrid(
                columns: Array(repeating: .init(.flexible()), count: 4),
                spacing: 20
            ) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        UserDefaults.standard.set(emoji, forKey: "user.emoji")
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 44))
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji
                                          ? Color.yellow.opacity(0.3)
                                          : Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding()
            .navigationTitle("Choose Emoji")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - CustomTextField

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.text = text
        tf.placeholder = placeholder
        tf.textAlignment = .center
        tf.textColor = .white
        tf.font = .systemFont(ofSize: 22, weight: .semibold)
        tf.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        tf.layer.cornerRadius = 12
        tf.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: CustomTextField
        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        @objc func changed(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }
    }
}