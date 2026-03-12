import SwiftUI

struct OnboardingView: View {
    @State private var currentStep: Int = 0
    @State private var selectedLevel: StabilityLevel = .I
    let onComplete: (StabilityLevel) -> Void
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack {
                TabView(selection: $currentStep) {
                    OnboardingStep1View(onNext: { currentStep = 1 })
                        .tag(0)
                    OnboardingStep2View(onNext: { currentStep = 2 })
                        .tag(1)
                    OnboardingStep3View(selectedLevel: $selectedLevel, onComplete: { onComplete(selectedLevel) })
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

struct OnboardingStep1View: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            Image(systemName: "lungs.fill")
                .font(.system(size: 80))
                .foregroundColor(DesignTokens.Colors.accentBase)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("360° Breathing")
                    .font(DesignTokens.Typography.title1())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Ribs expand in a circle.\nExhale - ribs down.")
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            
            Spacer()
            
            PillButton(title: "Next", action: onNext)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
        }
    }
}

struct OnboardingStep2View: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            Image(systemName: "figure.core.training")
                .font(.system(size: 80))
                .foregroundColor(DesignTokens.Colors.accentBase)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Anti-Movements")
                    .font(DesignTokens.Typography.title1())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.accentBase)
                        Text("Don't break the lower back")
                            .font(DesignTokens.Typography.callout())
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.accentBase)
                        Text("Don't let pelvis/ribs shift")
                            .font(DesignTokens.Typography.callout())
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            
            Spacer()
            
            PillButton(title: "Next", action: onNext)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
        }
    }
}

struct OnboardingStep3View: View {
    @Binding var selectedLevel: StabilityLevel
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            Image(systemName: "hourglass")
                .font(.system(size: 80))
                .foregroundColor(DesignTokens.Colors.accentBase)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("How It Works")
                    .font(DesignTokens.Typography.title1())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("6 protocols × 5 minutes\nLarge timer, voice cues\nRate difficulty after each session")
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Starting Level:")
                        .font(DesignTokens.Typography.callout())
                        .foregroundColor(.white.opacity(0.9))
                    
                    Picker("Level", selection: $selectedLevel) {
                        Text("Stability I").tag(StabilityLevel.I)
                        Text("Stability II").tag(StabilityLevel.II)
                        Text("Stability III").tag(StabilityLevel.III)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.top, DesignTokens.Spacing.lg)
            }
            
            Spacer()
            
            PillButton(title: "Get Started", action: onComplete)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
        }
    }
}

