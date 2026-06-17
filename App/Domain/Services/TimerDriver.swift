import Foundation

final class TimerDriver {
  private var timer: Timer?

  init(interval: TimeInterval = 1, onTick: @escaping @MainActor () -> Void) {
    timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
      Task { @MainActor in
        onTick()
      }
    }
    timer?.tolerance = 0.2
  }

  deinit {
    timer?.invalidate()
  }
}
