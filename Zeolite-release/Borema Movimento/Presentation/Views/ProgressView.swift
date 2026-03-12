import SwiftUI

struct ProgressView: View {
    @StateObject var viewModel: ProgressViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground(configuration: .darkGold)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Заголовок
                        HStack {
                            Text("Progress")
                                .font(DesignTokens.Typography.title1())
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.Colors.accentGold)
                            Spacer()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.xl)
                        
                        StabilityCard(level: viewModel.stabilityLevel, cleanStreak: viewModel.cleanStreak)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        
                        WeekTimelineView(model: viewModel.week)
                            .frame(height: 180)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        
                        ProtocolsDonutView(model: viewModel.donut)
                            .frame(minHeight: 260)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.top, DesignTokens.Spacing.lg)
                        
                        ProtocolDifficultyBarsView(model: viewModel.bars)
                            .frame(minHeight: 220)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.top, DesignTokens.Spacing.lg)
                        
                        CleanVsFlagsPieView(model: viewModel.cleanPie)
                            .frame(minHeight: 220)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.bottom, DesignTokens.Spacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(DesignTokens.Colors.accentGold)
                        .font(.body.weight(.semibold))
                        .padding(.trailing, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.md)
                    }
                    Spacer()
                }
            )
            .onAppear {
                viewModel.load()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct StabilityCard: View {
    let level: StabilityLevel
    let cleanStreak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DesignTokens.Colors.accentGold)
                
                Spacer()
                
                Text("Stability \(String(describing: level))")
                    .font(DesignTokens.Typography.title2())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text("\(cleanStreak) clean days in a row")
                .font(DesignTokens.Typography.body())
                .foregroundColor(.white.opacity(0.8))
            
            if cleanStreak >= 3 && level != .III {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(DesignTokens.Colors.accentGold)
                    Text("Ready to move up to Level \(String(level.rawValue + 1))!")
                        .font(DesignTokens.Typography.callout())
                        .foregroundColor(DesignTokens.Colors.accentGold)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.accentGold.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

