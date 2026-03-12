import SwiftUI

struct SessionView: View {
    @StateObject var viewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var stoppedSession: SessionDTO?
    @State private var hasStarted = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                Text("Protocol • Level \(String(viewModel.phases.level))")
                    .font(DesignTokens.Typography.callout())
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, DesignTokens.Spacing.md)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.timerBackground, lineWidth: 12)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(DesignTokens.Colors.timerActive, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: viewModel.progress)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text(viewModel.timeLeft)
                            .font(DesignTokens.Typography.largeTitle())
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(viewModel.phaseText)
                            .font(DesignTokens.Typography.title3())
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let side = viewModel.sideText {
                            Text("Side: \(side)")
                                .font(DesignTokens.Typography.callout())
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    if !hasStarted {
                        PillButton(title: "Start", action: {
                            viewModel.startSession()
                            hasStarted = true
                        })
                    } else if viewModel.isPaused {
                        PillButton(title: "Resume", action: viewModel.resume)
                    } else {
                        PillButton(title: "Pause", action: viewModel.pause)
                    }
                    
                    if hasStarted {
                        PillButton(title: "Stop", action: stopSession)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $stoppedSession) { session in
            PostSessionLogView(
                viewModel: DependencyContainer.shared.makePostSessionLogViewModel(),
                sessionId: session.id,
                onDismiss: { dismiss() }
            )
        }
        .onChange(of: viewModel.sessionCompleted) { completed in
            if completed && !hasStarted {
                return
            }
            if completed {
                stopSession()
            }
        }
    }
    
    private func stopSession() {
        if let session = viewModel.stop() {
            stoppedSession = session
        }
    }
}

