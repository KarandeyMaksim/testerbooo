import SwiftUI

struct PostSessionLogView: View {
    @StateObject var viewModel: PostSessionLogViewModel
    @Environment(\.dismiss) var dismiss
    let sessionId: UUID
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                Text("How was it?")
                    .font(DesignTokens.Typography.title1())
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.accentGold)
                    .padding(.top, DesignTokens.Spacing.xxl)
                
                VStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("Difficulty: \(Int(viewModel.difficulty))")
                                .font(DesignTokens.Typography.body())
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.Colors.accentGold)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("0")
                                .font(DesignTokens.Typography.caption())
                                .foregroundColor(.white.opacity(0.8))
                            
                            Slider(value: $viewModel.difficulty, in: 0...10, step: 1)
                                .accentColor(DesignTokens.Colors.accentGold)
                            
                            Text("10")
                                .font(DesignTokens.Typography.caption())
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.Colors.accentGold.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Toggle(isOn: $viewModel.flagExt) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(DesignTokens.Colors.accentGold)
                                    .font(.system(size: 20))
                                Text("Pulled into extension")
                                    .font(DesignTokens.Typography.body())
                                    .foregroundColor(.white)
                            }
                        }
                        .tint(DesignTokens.Colors.accentGold)
                        
                        Toggle(isOn: $viewModel.flagRot) {
                            HStack {
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundColor(DesignTokens.Colors.accentGold)
                                    .font(.system(size: 20))
                                Text("Pulled into rotation")
                                    .font(DesignTokens.Typography.body())
                                    .foregroundColor(.white)
                            }
                        }
                        .tint(DesignTokens.Colors.accentGold)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.Colors.accentGold.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Notes (optional)")
                            .font(DesignTokens.Typography.callout())
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.accentGold)
                        
                        TextField("Add note...", text: $viewModel.note)
                            .textFieldStyle(.plain)
                            .padding(DesignTokens.Spacing.sm)
                            .frame(height: 44)
                            .background(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.CornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                                    .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.Colors.accentGold.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                
                Spacer()
                
                Button(action: save) {
                    Text("Save")
                        .font(DesignTokens.Typography.body())
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.accentOn)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignTokens.Colors.accentGold)
                        .cornerRadius(DesignTokens.CornerRadius.pill)
                        .shadow(color: DesignTokens.Colors.accentGold.opacity(0.4), radius: 12, x: 0, y: 4)
                        .shadow(color: DesignTokens.Colors.accentGold.opacity(0.2), radius: 24, x: 0, y: 8)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func save() {
        let result = viewModel.save(sessionId: sessionId)
        
        if let result = result {
            if result.recommendUp {
                print("Recommend level up!")
            } else if result.recommendDown {
                print("Recommend level down!")
            }
        }
        
        dismiss()
        onDismiss()
    }
}

