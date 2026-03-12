import UIKit
import SwiftUI

// MARK: - UIKit Animated Background View

final class AnimatedBackgroundView: UIView {
    
    // MARK: - Configuration
    
    struct Configuration {
        var primaryColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.15)
        var secondaryColor: UIColor = UIColor.systemPurple.withAlphaComponent(0.1)
        var accentColor: UIColor = UIColor.systemTeal.withAlphaComponent(0.08)
        var backgroundColor: UIColor = .systemBackground
        var particleCount: Int = 6
        var particleSizeRange: ClosedRange<CGFloat> = 0.3...0.6 // relative to screen width
        var animationSpeed: AnimationSpeed = .slow
        
        enum AnimationSpeed: CGFloat {
            case slow = 12
            case medium = 8
            case fast = 5
        }
        
        static let `default` = Configuration()
        
        static let subtle = Configuration(
            primaryColor: UIColor.systemGray.withAlphaComponent(0.08),
            secondaryColor: UIColor.systemGray2.withAlphaComponent(0.06),
            accentColor: UIColor.systemGray3.withAlphaComponent(0.04),
            particleCount: 4
        )
        
        static let warm = Configuration(
            primaryColor: UIColor.systemOrange.withAlphaComponent(0.12),
            secondaryColor: UIColor.systemYellow.withAlphaComponent(0.08),
            accentColor: UIColor.systemRed.withAlphaComponent(0.06)
        )
        
        static let cool = Configuration(
            primaryColor: UIColor.systemBlue.withAlphaComponent(0.12),
            secondaryColor: UIColor.systemCyan.withAlphaComponent(0.08),
            accentColor: UIColor.systemIndigo.withAlphaComponent(0.06)
        )
        
        // MARK: - Dark Gold Theme
        
        /// Золотой цвет (основной акцент)
        private static let gold = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        
        /// Тёмная тема с маленькими золотыми частицами
        static let darkGold = Configuration(
            primaryColor: gold.withAlphaComponent(0.25),
            secondaryColor: gold.withAlphaComponent(0.15),
            accentColor: gold.withAlphaComponent(0.08),
            backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0), // почти чёрный с лёгким синим оттенком
            particleCount: 12,
            particleSizeRange: 0.08...0.15, // маленькие частицы
            animationSpeed: .slow
        )
        
        /// Альтернатива: более тёплый тёмный фон
        static let darkGoldWarm = Configuration(
            primaryColor: gold.withAlphaComponent(0.3),
            secondaryColor: UIColor(red: 180/255, green: 140/255, blue: 50/255, alpha: 0.2), // тёмное золото
            accentColor: UIColor(red: 255/255, green: 215/255, blue: 100/255, alpha: 0.1), // светлое золото
            backgroundColor: UIColor(red: 0.08, green: 0.06, blue: 0.04, alpha: 1.0), // тёплый чёрный
            particleCount: 15,
            particleSizeRange: 0.05...0.12, // ещё меньше частицы
            animationSpeed: .slow
        )
        
        /// Искрящийся вариант с большим количеством мелких частиц
        static let darkGoldSparkle = Configuration(
            primaryColor: gold.withAlphaComponent(0.35),
            secondaryColor: gold.withAlphaComponent(0.2),
            accentColor: UIColor.white.withAlphaComponent(0.1), // белые искры
            backgroundColor: .black,
            particleCount: 20,
            particleSizeRange: 0.03...0.08, // очень маленькие
            animationSpeed: .medium
        )
    }
    
    // MARK: - Properties
    
    private var configuration: Configuration
    private var particles: [ParticleLayer] = []
    private var displayLink: CADisplayLink?
    private var isAnimating = false
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .default) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = configuration.backgroundColor
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    
    private func setupParticles() {
        particles.forEach { $0.removeFromSuperlayer() }
        particles.removeAll()
        
        let colors = [
            configuration.primaryColor,
            configuration.secondaryColor,
            configuration.accentColor
        ]
        
        let sizeRange = configuration.particleSizeRange
        
        for i in 0..<configuration.particleCount {
            let particle = ParticleLayer()
            particle.fillColor = colors[i % colors.count].cgColor
            
            let size = CGFloat.random(in: bounds.width * sizeRange.lowerBound...bounds.width * sizeRange.upperBound)
            particle.frame = CGRect(
                x: CGFloat.random(in: -size/2...bounds.width - size/2),
                y: CGFloat.random(in: -size/2...bounds.height - size/2),
                width: size,
                height: size
            )
            
            particle.path = createBlobPath(in: particle.bounds)
            particle.initialPosition = particle.position
            particle.phase = CGFloat.random(in: 0...(.pi * 2))
            particle.particleSpeed = CGFloat.random(in: 0.3...0.7)
            particle.amplitude = CGFloat.random(in: 20...50)
            
            layer.addSublayer(particle)
            particles.append(particle)
        }
    }
    
    private func createBlobPath(in rect: CGRect) -> CGPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let points = 6
        let angleStep = (CGFloat.pi * 2) / CGFloat(points)
        
        var controlPoints: [(point: CGPoint, radius: CGFloat)] = []
        
        for i in 0..<points {
            let angle = angleStep * CGFloat(i) - .pi / 2
            let randomRadius = radius * CGFloat.random(in: 0.8...1.0)
            let point = CGPoint(
                x: center.x + cos(angle) * randomRadius,
                y: center.y + sin(angle) * randomRadius
            )
            controlPoints.append((point, randomRadius))
        }
        
        path.move(to: controlPoints[0].point)
        
        for i in 0..<points {
            let current = controlPoints[i]
            let next = controlPoints[(i + 1) % points]
            
            let midPoint = CGPoint(
                x: (current.point.x + next.point.x) / 2,
                y: (current.point.y + next.point.y) / 2
            )
            
            path.addQuadCurve(to: midPoint, controlPoint: current.point)
            path.addQuadCurve(to: next.point, controlPoint: midPoint)
        }
        
        path.close()
        return path.cgPath
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if particles.isEmpty || particles.first?.bounds.width ?? 0 < 10 {
            setupParticles()
            startAnimating()
        }
    }
    
    // MARK: - Animation
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        } else {
            displayLink?.preferredFramesPerSecond = 60
        }
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimating() {
        isAnimating = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateAnimation() {
        let time = CACurrentMediaTime()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        for particle in particles {
            let phase = particle.phase
            let speed = particle.particleSpeed / configuration.animationSpeed.rawValue
            let amplitude = particle.amplitude
            
            let xOffset = sin(time * speed + phase) * amplitude
            let yOffset = cos(time * speed * 0.7 + phase) * amplitude * 0.8
            
            particle.position = CGPoint(
                x: particle.initialPosition.x + xOffset,
                y: particle.initialPosition.y + yOffset
            )
            
            let scale = 1.0 + sin(time * speed * 0.5 + phase) * 0.05
            particle.transform = CATransform3DMakeScale(scale, scale, 1)
        }
        
        CATransaction.commit()
    }
    
    // MARK: - Public Methods
    
    func updateConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
        backgroundColor = configuration.backgroundColor
        setupParticles()
    }
    
    // MARK: - Lifecycle
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow != nil {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    deinit {
        stopAnimating()
    }
}

// MARK: - Particle Layer

private final class ParticleLayer: CAShapeLayer {
    var initialPosition: CGPoint = .zero
    var phase: CGFloat = 0
    var particleSpeed: CGFloat = 1
    var amplitude: CGFloat = 30
}

// MARK: - SwiftUI Bridge

struct AnimatedBackground: UIViewRepresentable {
    
    var configuration: AnimatedBackgroundView.Configuration
    
    init(configuration: AnimatedBackgroundView.Configuration = .default) {
        self.configuration = configuration
    }
    
    func makeUIView(context: Context) -> AnimatedBackgroundView {
        let view = AnimatedBackgroundView(configuration: configuration)
        return view
    }
    
    func updateUIView(_ uiView: AnimatedBackgroundView, context: Context) {
        uiView.updateConfiguration(configuration)
    }
}

// MARK: - SwiftUI View Modifier

struct AnimatedBackgroundModifier: ViewModifier {
    
    var configuration: AnimatedBackgroundView.Configuration
    
    func body(content: Content) -> some View {
        ZStack {
            AnimatedBackground(configuration: configuration)
                .ignoresSafeArea()
            
            content
        }
    }
}

extension View {
    func animatedBackground(
        _ configuration: AnimatedBackgroundView.Configuration = .default
    ) -> some View {
        modifier(AnimatedBackgroundModifier(configuration: configuration))
    }
}

// MARK: - Preview

struct AnimatedBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                List {
                    ForEach(0..<10) { index in
                        Text("Item \(index)")
                    }
                }
                .background(Color.clear)
                .navigationTitle("Demo")
            }
            .animatedBackground()
            .previewDisplayName("Default")
            
            VStack(spacing: 20) {
                Text("Subtle Background")
                    .font(.largeTitle)
                
                Text("Perfect for content-heavy screens")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animatedBackground(.subtle)
            .previewDisplayName("Subtle")
            
            Text("Warm Theme")
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animatedBackground(.warm)
                .previewDisplayName("Warm")
            
            Text("Cool Theme")
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animatedBackground(.cool)
                .previewDisplayName("Cool")
            
            // MARK: - Dark Gold Previews
            
            VStack(spacing: 20) {
                Text("Dark Gold")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Elegant dark theme")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animatedBackground(.darkGold)
            .previewDisplayName("Dark Gold")
            
            VStack(spacing: 20) {
                Text("Dark Gold Warm")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Warm variation")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animatedBackground(.darkGoldWarm)
            .previewDisplayName("Dark Gold Warm")
            
            VStack(spacing: 20) {
                Text("Sparkle")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Many tiny particles")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animatedBackground(.darkGoldSparkle)
            .previewDisplayName("Dark Gold Sparkle")
        }
    }
}
