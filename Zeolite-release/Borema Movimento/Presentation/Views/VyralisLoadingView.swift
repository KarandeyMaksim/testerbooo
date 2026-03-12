import SwiftUI

struct VyralisLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            AnimatedBackground(configuration: .darkGold)
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                
                // Иконка с пульсацией
                ZStack {
                    // Внешний круг с пульсацией
                    Circle()
                        .fill(DesignTokens.Colors.accentGold.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .opacity(1.0 - pulseScale * 0.5)
                    
                    // Средний круг
                    Circle()
                        .fill(DesignTokens.Colors.accentGold.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale * 0.9)
                    
                    // Внутренний круг с иконкой
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.accentGold.opacity(0.4))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.accentGold)
                            .scaleEffect(scale)
                    }
                }
                .opacity(opacity)
                
                // Индикатор загрузки
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.accentGold.opacity(0.2), lineWidth: 5)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accentGold, DesignTokens.Colors.accentGold.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .opacity(opacity)
                
                // Текст загрузки
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Loading")
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(DesignTokens.Colors.accentGold)
                    
                    Text("Please wait...")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Анимация появления
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
            }
            
            // Анимация вращения индикатора
            withAnimation(
                Animation.linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            // Анимация пульсации иконки
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
            }
            
            // Анимация пульсации внешнего круга
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.3
            }
        }
    }
}

