import Foundation

public enum StabilityLevel: Int, CaseIterable, CustomStringConvertible {
    case I = 1
    case II = 2
    case III = 3
    
    public var description: String {
        switch self {
        case .I: return "I"
        case .II: return "II"
        case .III: return "III"
        }
    }
}

public struct DayPracticePoint: Identifiable, Equatable {
    public let id: UUID
    public let weekdayShort: String
    public let dateISO: String
    public let hasSession: Bool
    public let difficulty: Int?
    public let flagExtension: Bool
    public let flagRotation: Bool
    public let level: StabilityLevel
    public let a11yText: String
    
    public init(id: UUID, weekdayShort: String, dateISO: String, hasSession: Bool, difficulty: Int?, flagExtension: Bool, flagRotation: Bool, level: StabilityLevel, a11yText: String) {
        self.id = id
        self.weekdayShort = weekdayShort
        self.dateISO = dateISO
        self.hasSession = hasSession
        self.difficulty = difficulty
        self.flagExtension = flagExtension
        self.flagRotation = flagRotation
        self.level = level
        self.a11yText = a11yText
    }
}

public struct WeekTimelineModel: Equatable {
    public let title: String
    public let points: [DayPracticePoint]
    
    public init(title: String, points: [DayPracticePoint]) {
        self.title = title
        self.points = points
    }
}

public struct ProtocolSlice: Identifiable, Equatable {
    public let id: UUID
    public let protocolName: String
    public let count: Int
    public let percent: Double
    public let a11yText: String
    
    public init(id: UUID, protocolName: String, count: Int, percent: Double, a11yText: String) {
        self.id = id
        self.protocolName = protocolName
        self.count = count
        self.percent = percent
        self.a11yText = a11yText
    }
}

public struct ProtocolsDonutModel: Equatable {
    public let title: String
    public let slices: [ProtocolSlice]
    public let caption: String
    
    public init(title: String, slices: [ProtocolSlice], caption: String) {
        self.title = title
        self.slices = slices
        self.caption = caption
    }
}

public struct ProtocolDifficultyBar: Identifiable, Equatable {
    public let id: UUID
    public let protocolName: String
    public let avgDifficulty: Double
    public let sessionsCount: Int
    public let a11yText: String
    
    public init(id: UUID, protocolName: String, avgDifficulty: Double, sessionsCount: Int, a11yText: String) {
        self.id = id
        self.protocolName = protocolName
        self.avgDifficulty = avgDifficulty
        self.sessionsCount = sessionsCount
        self.a11yText = a11yText
    }
}

public struct ProtocolDifficultyBarsModel: Equatable {
    public let title: String
    public let bars: [ProtocolDifficultyBar]
    
    public init(title: String, bars: [ProtocolDifficultyBar]) {
        self.title = title
        self.bars = bars
    }
}

public struct CleanVsFlagsPieModel: Equatable {
    public let title: String
    public let cleanPct: Double
    public let extPct: Double
    public let rotPct: Double
    public let a11yText: String
    
    public init(title: String, cleanPct: Double, extPct: Double, rotPct: Double, a11yText: String) {
        self.title = title
        self.cleanPct = cleanPct
        self.extPct = extPct
        self.rotPct = rotPct
        self.a11yText = a11yText
    }
}

public enum PhaseType: Int {
    case inhale = 0
    case exhale = 1
    case neutral = 2
    case sideSwitch = 3
}

public struct PhaseBand: Identifiable, Equatable {
    public let id: UUID
    public let type: PhaseType
    public let startSec: Int
    public let durationSec: Int
    public let side: String?
    public let a11yText: String
    
    public init(id: UUID, type: PhaseType, startSec: Int, durationSec: Int, side: String?, a11yText: String) {
        self.id = id
        self.type = type
        self.startSec = startSec
        self.durationSec = durationSec
        self.side = side
        self.a11yText = a11yText
    }
}

public struct SessionPhasesModel: Equatable {
    public let title: String
    public let bands: [PhaseBand]
    
    public init(title: String, bands: [PhaseBand]) {
        self.title = title
        self.bands = bands
    }
}

struct BuildProgressChartsOutput {
    let weekTimeline: WeekTimelineModel
    let protocolsDonut: ProtocolsDonutModel
    let difficultyBars: ProtocolDifficultyBarsModel
    let cleanPie: CleanVsFlagsPieModel
}

protocol BuildProgressChartsUseCase {
    func execute(from: Date, to: Date, sessions: [SessionDTO], protocols: [ProtocolDTO]) -> BuildProgressChartsOutput
}

class BuildProgressChartsUseCaseImpl: BuildProgressChartsUseCase {
    func execute(from: Date, to: Date, sessions: [SessionDTO], protocols: [ProtocolDTO]) -> BuildProgressChartsOutput {
        let weekTimeline = buildWeekTimeline(from: from, to: to, sessions: sessions)
        let donut = buildProtocolsDonut(sessions: sessions, protocols: protocols)
        let bars = buildDifficultyBars(sessions: sessions, protocols: protocols)
        let cleanPie = buildCleanPie(sessions: sessions)
        
        return BuildProgressChartsOutput(weekTimeline: weekTimeline, protocolsDonut: donut, difficultyBars: bars, cleanPie: cleanPie)
    }
    
    private func buildWeekTimeline(from: Date, to: Date, sessions: [SessionDTO]) -> WeekTimelineModel {
        let calendar = Calendar.current
        var points: [DayPracticePoint] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: from) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySessions = sessions.filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            
            if let session = daySessions.first {
                let level = StabilityLevel(rawValue: session.level) ?? .I
                let point = DayPracticePoint(
                    id: UUID(),
                    weekdayShort: FormattersService.weekdayShort(from: date),
                    dateISO: FormattersService.dateISO(from: date),
                    hasSession: true,
                    difficulty: session.difficulty,
                    flagExtension: session.flagExtension,
                    flagRotation: session.flagRotation,
                    level: level,
                    a11yText: "Day: \(FormattersService.weekdayShort(from: date)), difficulty \(session.difficulty ?? 0)"
                )
                points.append(point)
            } else {
                let point = DayPracticePoint(
                    id: UUID(),
                    weekdayShort: FormattersService.weekdayShort(from: date),
                    dateISO: FormattersService.dateISO(from: date),
                    hasSession: false,
                    difficulty: nil,
                    flagExtension: false,
                    flagRotation: false,
                    level: .I,
                    a11yText: "Day: \(FormattersService.weekdayShort(from: date)), no session"
                )
                points.append(point)
            }
        }
        
        return WeekTimelineModel(title: "Week", points: points)
    }
    
    private func buildProtocolsDonut(sessions: [SessionDTO], protocols: [ProtocolDTO]) -> ProtocolsDonutModel {
        var counts: [UUID: Int] = [:]
        
        for session in sessions {
            counts[session.protocolId, default: 0] += 1
        }
        
        let total = sessions.count
        let slices = counts.map { (protoId, count) -> ProtocolSlice in
            let proto = protocols.first { $0.id == protoId }
            let percent = total > 0 ? Double(count) / Double(total) : 0.0
            return ProtocolSlice(
                id: UUID(),
                protocolName: proto?.name ?? "Unknown",
                count: count,
                percent: percent,
                a11yText: "\(proto?.name ?? "Unknown") \(Int(percent * 100))%"
            )
        }
        
        return ProtocolsDonutModel(title: "Protocol Usage", slices: slices, caption: "")
    }
    
    private func buildDifficultyBars(sessions: [SessionDTO], protocols: [ProtocolDTO]) -> ProtocolDifficultyBarsModel {
        var protocolData: [UUID: (sum: Int, count: Int)] = [:]
        
        for session in sessions {
            if let diff = session.difficulty {
                let existing = protocolData[session.protocolId] ?? (sum: 0, count: 0)
                protocolData[session.protocolId] = (sum: existing.sum + diff, count: existing.count + 1)
            }
        }
        
        let bars = protocols.map { proto -> ProtocolDifficultyBar in
            let data = protocolData[proto.id] ?? (sum: 0, count: 0)
            let avg = data.count > 0 ? Double(data.sum) / Double(data.count) : 0.0
            return ProtocolDifficultyBar(
                id: UUID(),
                protocolName: proto.name,
                avgDifficulty: avg,
                sessionsCount: data.count,
                a11yText: "\(proto.name) avg difficulty \(String(format: "%.1f", avg))"
            )
        }
        
        return ProtocolDifficultyBarsModel(title: "Average Difficulty", bars: bars)
    }
    
    private func buildCleanPie(sessions: [SessionDTO]) -> CleanVsFlagsPieModel {
        var clean = 0
        var ext = 0
        var rot = 0
        
        for session in sessions {
            if !session.flagExtension && !session.flagRotation {
                clean += 1
            }
            if session.flagExtension { ext += 1 }
            if session.flagRotation { rot += 1 }
        }
        
        let total = sessions.count
        let cleanPct = total > 0 ? Double(clean) / Double(total) : 0.0
        let extPct = total > 0 ? Double(ext) / Double(total) : 0.0
        let rotPct = total > 0 ? Double(rot) / Double(total) : 0.0
        
        return CleanVsFlagsPieModel(
            title: "Form Quality",
            cleanPct: cleanPct,
            extPct: extPct,
            rotPct: rotPct,
            a11yText: "Clean \(Int(cleanPct * 100))%, extension \(Int(extPct * 100))%, rotation \(Int(rotPct * 100))%"
        )
    }
}

