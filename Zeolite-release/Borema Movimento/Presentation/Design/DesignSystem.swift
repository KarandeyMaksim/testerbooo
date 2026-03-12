import SwiftUI

struct DesignTokens {
    struct Colors {
        // Темный фон
        static let bgStart = Color(red: 0.1, green: 0.1, blue: 0.1)
        static let bgEnd = Color(red: 0.05, green: 0.05, blue: 0.05)
        static let bgTint = Color(red: 0.22, green: 0.22, blue: 0.22) // Светлее для видимости на темном фоне
        
        // Желто-золотые акцентные цвета
        static let accentBase = Color(red: 1.0, green: 0.843, blue: 0.0) // Желтый
        static let accentGold = Color(red: 1.0, green: 0.843, blue: 0.0) // Золотой акцент
        static let accentGlow = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.25)
        static let accentOn = Color.black
        
        // Темные поверхности
        static let surface = Color(red: 0.25, green: 0.25, blue: 0.25) // Светлее для лучшей видимости
        static let textOnSurface = Color.white
        
        // Таймер с желтым акцентом
        static let timerActive = Color(red: 1.0, green: 0.843, blue: 0.0)
        static let timerBackground = Color.white.opacity(0.15)
        
        // Уровни с желтыми оттенками
        static let levelI = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.4)
        static let levelII = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.7)
        static let levelIII = Color(red: 1.0, green: 0.843, blue: 0.0)
        
        // Графики с желтым
        static let chartStroke = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.90)
        static let chartFill = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.35)
        static let chartSoft = Color.white.opacity(0.7)
        static let chartGrid = Color.white.opacity(0.15)
        static let chartWarn = Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.90)
    }
    
    struct Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 24
    }
    
    struct Typography {
        static func largeTitle() -> Font {
            return .system(size: 48, weight: .bold, design: .default).monospacedDigit()
        }
        
        static func title1() -> Font {
            return .system(size: 32, weight: .semibold, design: .default).monospacedDigit()
        }
        
        static func title2() -> Font {
            return .system(size: 24, weight: .semibold, design: .default)
        }
        
        static func title3() -> Font {
            return .system(size: 20, weight: .semibold, design: .default)
        }
        
        static func body() -> Font {
            return .system(size: 17, weight: .regular, design: .default)
        }
        
        static func callout() -> Font {
            return .system(size: 16, weight: .regular, design: .default)
        }
        
        static func caption() -> Font {
            return .system(size: 14, weight: .regular, design: .default)
        }
    }
}

struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Темный фон
            Color(red: 0.05, green: 0.05, blue: 0.05)
                .ignoresSafeArea()
            
            // Градиент поверх
            LinearGradient(
                gradient: Gradient(colors: [DesignTokens.Colors.bgEnd, DesignTokens.Colors.bgStart]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        }
    }
}

struct PillButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.body())
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.textOnSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(DesignTokens.Colors.surface)
                .cornerRadius(DesignTokens.CornerRadius.pill)
                .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 8)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct ProtocolCard: View {
    let title: String
    let iconName: String
    let level: StabilityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(DesignTokens.Colors.accentGold)
                    
                    Spacer()
                    
                    Text("\(String(describing: level))")
                        .font(DesignTokens.Typography.caption())
                        .fontWeight(.bold)
                        .foregroundColor(DesignTokens.Colors.accentOn)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(levelColor(level))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Text(title)
                    .font(DesignTokens.Typography.callout())
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textOnSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("5:00")
                    .font(DesignTokens.Typography.caption())
                    .foregroundColor(DesignTokens.Colors.textOnSurface.opacity(0.6))
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Фиксированная высота для всех карточек
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(isSelected ? DesignTokens.Colors.accentGold : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? DesignTokens.Colors.accentGold.opacity(0.2) : Color.black.opacity(0.12), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 4 : 2)
        }
    }
    
    private func levelColor(_ level: StabilityLevel) -> Color {
        switch level {
        case .I: return DesignTokens.Colors.levelI
        case .II: return DesignTokens.Colors.levelII
        case .III: return DesignTokens.Colors.levelIII
        }
    }
}

