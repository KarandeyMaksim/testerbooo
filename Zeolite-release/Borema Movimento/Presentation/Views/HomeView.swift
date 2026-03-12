import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var showSettings = false
    @State private var showProgress = false
    @State private var navigateToSession = false
    @State private var sessionData: (SessionDTO, LevelProfileDTO)?
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground(configuration: .darkGold)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Кастомный заголовок с кнопками
                    HStack {
                        Button(action: { showProgress = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 22))
                                .foregroundColor(DesignTokens.Colors.accentGold)
                        }
                        
                        Spacer()
                        
                        Text("Bitelo Morina")
                            .font(DesignTokens.Typography.title2())
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.accentGold)
                        
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(DesignTokens.Colors.accentGold)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.sm)
                    
                    ScrollView {
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            if viewModel.recommendUp {
                                RecommendationBanner(text: "3 clean sessions! Consider moving up to Level \(viewModel.selectedLevel.rawValue + 1)")
                                    .padding(.horizontal, DesignTokens.Spacing.md)
                            }
                            
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Text("Stability Level")
                                    .font(DesignTokens.Typography.callout())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Picker("Level", selection: $viewModel.selectedLevel) {
                                    Text("I").tag(StabilityLevel.I)
                                    Text("II").tag(StabilityLevel.II)
                                    Text("III").tag(StabilityLevel.III)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, DesignTokens.Spacing.md)
                            }
                            .padding(.top, DesignTokens.Spacing.md)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
                                ForEach(viewModel.protocols) { proto in
                                    ProtocolCard(
                                        title: proto.name,
                                        iconName: iconForProtocol(proto.slug),
                                        level: viewModel.selectedLevel,
                                        isSelected: viewModel.selectedProtocolId == proto.id,
                                        action: { viewModel.selectProtocol(proto.id) }
                                    )
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            
                            Button(action: startSession) {
                                Text("Start 5:00")
                                    .font(DesignTokens.Typography.body())
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignTokens.Colors.accentOn)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(viewModel.canStart ? DesignTokens.Colors.accentGold : DesignTokens.Colors.surface)
                                    .cornerRadius(DesignTokens.CornerRadius.pill)
                                    .shadow(color: viewModel.canStart ? DesignTokens.Colors.accentGold.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 4)
                                    .shadow(color: viewModel.canStart ? DesignTokens.Colors.accentGold.opacity(0.2) : Color.clear, radius: 24, x: 0, y: 8)
                            }
                            .disabled(!viewModel.canStart)
                            .opacity(viewModel.canStart ? 1.0 : 0.5)
                            .padding(.horizontal, DesignTokens.Spacing.xl)
                            .padding(.vertical, DesignTokens.Spacing.lg)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: DependencyContainer.shared.makeSettingsViewModel())
            }
            .sheet(isPresented: $showProgress) {
                ProgressView(viewModel: DependencyContainer.shared.makeProgressViewModel())
            }
            .background(
                NavigationLink(
                    destination: sessionData.map { data in
                        SessionView(
                            viewModel: DependencyContainer.shared.makeSessionViewModel(session: data.0, phases: data.1)
                        )
                    },
                    isActive: $navigateToSession
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(.stack)
    }
    
    private func startSession() {
        if let data = viewModel.start() {
            sessionData = data
            navigateToSession = true
        }
    }
    
    private func iconForProtocol(_ slug: String) -> String {
        switch slug {
        case "breathing_supine":
            return "lungs.fill"
        case "bear_quadruped":
            return "pawprint.fill"
        case "pallof_hold":
            return "hand.raised.fill"
        case "dead_bug":
            return "ant.fill"
        case "half_kneel_pressout":
            return "figure.strengthtraining.traditional"
        case "side_plank_breathing":
            return "triangle.fill"
        default:
            return "figure.core.training"
        }
    }
}

struct RecommendationBanner: View {
    let text: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "bolt.heart.fill")
                .foregroundColor(DesignTokens.Colors.accentGold)
                .font(.system(size: 18))
            
            Text(text)
                .font(DesignTokens.Typography.callout())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(DesignTokens.Colors.accentGold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.accentGold.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

