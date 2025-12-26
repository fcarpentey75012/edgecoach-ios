import SwiftUI

/// Conteneur générique pour une expérience type "Story"
/// Gère la navigation, le timer automatique et les barres de progression.
struct StoryContainerView<Content: View>: View {
    // MARK: - Properties
    let count: Int
    let content: (Int) -> Content
    let onComplete: () -> Void
    
    @State private var currentIndex = 0
    @State private var timeProgress: CGFloat = 0
    @State private var isPaused = false
    
    // Configuration
    private let timerStep = 0.05
    private let slideDuration = 5.0 // secondes par slide
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // MARK: - Init
    
    init(count: Int, onComplete: @escaping () -> Void, @ViewBuilder content: @escaping (Int) -> Content) {
        self.count = count
        self.onComplete = onComplete
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Fond noir par défaut pour l'immersion
            Color.black.ignoresSafeArea()
            
            // Contenu de la slide courante
            content(currentIndex)
                .id(currentIndex) // Force la transition
                .transition(.opacity)
                .animation(.easeInOut, value: currentIndex)
            
            // Zone tactile transparente pour la navigation
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .onTapGesture {
                        previousSlide()
                    }
                
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .onTapGesture {
                        nextSlide()
                    }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPaused = true }
                    .onEnded { _ in isPaused = false }
            )
            
            // Barres de progression (Header)
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { index in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: progressWidth(for: index, totalWidth: geo.size.width))
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.top, 60) // Safe area manuelle pour effet immersif
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            
            if timeProgress < 1.0 {
                timeProgress += timerStep / slideDuration
            } else {
                nextSlide()
            }
        }
    }
    
    // MARK: - Logic
    
    private func nextSlide() {
        if currentIndex < count - 1 {
            withAnimation {
                currentIndex += 1
                timeProgress = 0
            }
            HapticManager.shared.playSelection()
        } else {
            onComplete()
        }
    }
    
    private func previousSlide() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
                timeProgress = 0
            }
            HapticManager.shared.playSelection()
        } else {
            // Restart current slide
            timeProgress = 0
        }
    }
    
    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            return totalWidth
        } else if index == currentIndex {
            return totalWidth * timeProgress
        } else {
            return 0
        }
    }
}
