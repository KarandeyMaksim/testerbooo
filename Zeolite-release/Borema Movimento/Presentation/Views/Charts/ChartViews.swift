import SwiftUI

struct WeekTimelineView: View {
    let model: WeekTimelineModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(model.title)
                .font(DesignTokens.Typography.title3())
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.accentGold)
            
            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
                ForEach(model.points) { point in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                                .frame(width: 40, height: 100)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(point))
                                .frame(width: 40, height: barHeight(point))
                        }
                        
                        Text(point.weekdayShort)
                            .font(DesignTokens.Typography.caption())
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
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
    
    private func barHeight(_ point: DayPracticePoint) -> CGFloat {
        guard point.hasSession, let difficulty = point.difficulty else {
            return 10
        }
        return CGFloat(difficulty) * 10 + 20
    }
    
    private func barColor(_ point: DayPracticePoint) -> Color {
        if !point.hasSession {
            return DesignTokens.Colors.chartGrid
        }
        if point.flagExtension || point.flagRotation {
            return DesignTokens.Colors.chartWarn
        }
        return DesignTokens.Colors.chartFill
    }
}

struct ProtocolsDonutView: View {
    let model: ProtocolsDonutModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(model.title)
                .font(DesignTokens.Typography.title3())
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.accentGold)
                .padding(.bottom, DesignTokens.Spacing.xs)
            
            if model.slices.isEmpty {
                Text("No sessions yet")
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(DesignTokens.Colors.surface)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(DesignTokens.Colors.accentGold.opacity(0.2), lineWidth: 1)
                    )
            } else {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        ForEach(Array(model.slices.enumerated()), id: \.element.id) { index, slice in
                            PieSliceView(
                                startAngle: startAngle(for: index),
                                endAngle: endAngle(for: index),
                                color: sliceColor(index: index)
                            )
                        }
                    }
                    .frame(width: 140, height: 140)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        ForEach(Array(model.slices.enumerated()), id: \.element.id) { index, slice in
                            HStack {
                                Circle()
                                    .fill(sliceColor(index: index))
                                    .frame(width: 12, height: 12)
                                
                                Text("\(slice.protocolName): \(Int(slice.percent * 100))%")
                                    .font(DesignTokens.Typography.caption())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(DesignTokens.Colors.accentGold.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: DesignTokens.Colors.accentGold.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let accumulated = model.slices.prefix(index).reduce(0.0) { $0 + $1.percent }
        return .degrees(accumulated * 360.0 - 90.0)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let accumulated = model.slices.prefix(index + 1).reduce(0.0) { $0 + $1.percent }
        return .degrees(accumulated * 360.0 - 90.0)
    }
    
    private func sliceColor(index: Int) -> Color {
        let colors = [DesignTokens.Colors.chartFill, DesignTokens.Colors.chartSoft, DesignTokens.Colors.accentBase, DesignTokens.Colors.levelII, DesignTokens.Colors.levelI, DesignTokens.Colors.chartWarn]
        return colors[index % colors.count]
    }
}

struct PieSliceView: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct ProtocolDifficultyBarsView: View {
    let model: ProtocolDifficultyBarsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(model.title)
                .font(DesignTokens.Typography.title3())
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.accentGold)
                .padding(.bottom, DesignTokens.Spacing.xs)
            
            if model.bars.isEmpty {
                Text("No data yet")
                    .font(DesignTokens.Typography.body())
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(DesignTokens.Colors.surface)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(DesignTokens.Colors.accentGold.opacity(0.2), lineWidth: 1)
                    )
            } else {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(model.bars) { bar in
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text(bar.protocolName)
                                .font(DesignTokens.Typography.caption())
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 100, alignment: .leading)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                                    .frame(height: 24)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(bar.sessionsCount >= 2 ? DesignTokens.Colors.chartFill : DesignTokens.Colors.chartGrid)
                                    .frame(width: nil, height: 24)
                                    .frame(maxWidth: .infinity)
                                    .layoutPriority(-1)
                            }
                            
                            Text(String(format: "%.1f", bar.avgDifficulty))
                                .font(DesignTokens.Typography.caption())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
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
    }
}

struct CleanVsFlagsPieView: View {
    let model: CleanVsFlagsPieModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(model.title)
                .font(DesignTokens.Typography.title3())
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.accentGold)
                .padding(.bottom, DesignTokens.Spacing.xs)
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: model.cleanPct)
                        .stroke(DesignTokens.Colors.chartFill, lineWidth: 16)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: model.cleanPct, to: model.cleanPct + model.extPct)
                        .stroke(DesignTokens.Colors.chartWarn, lineWidth: 16)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: model.cleanPct + model.extPct, to: 1.0)
                        .stroke(DesignTokens.Colors.chartSoft, lineWidth: 16)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(model.cleanPct * 100))%")
                        .font(DesignTokens.Typography.title2())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Circle()
                            .fill(DesignTokens.Colors.chartFill)
                            .frame(width: 12, height: 12)
                        Text("Clean: \(Int(model.cleanPct * 100))%")
                            .font(DesignTokens.Typography.caption())
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Circle()
                            .fill(DesignTokens.Colors.chartWarn)
                            .frame(width: 12, height: 12)
                        Text("Extension: \(Int(model.extPct * 100))%")
                            .font(DesignTokens.Typography.caption())
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Circle()
                            .fill(DesignTokens.Colors.chartSoft)
                            .frame(width: 12, height: 12)
                        Text("Rotation: \(Int(model.rotPct * 100))%")
                            .font(DesignTokens.Typography.caption())
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.accentGold.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: DesignTokens.Colors.accentGold.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

