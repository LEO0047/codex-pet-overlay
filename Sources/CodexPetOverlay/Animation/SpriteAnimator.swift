import Foundation

final class SpriteAnimator {
    private var timer: Timer?
    private var frameIndex = 0
    private let onFrame: (Int) -> Void
    var isPaused = false

    init(onFrame: @escaping (Int) -> Void) {
        self.onFrame = onFrame
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            self.frameIndex = (self.frameIndex + 1) % 8
            self.onFrame(self.frameIndex)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
