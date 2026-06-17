import Foundation

final class UserDefaultsAlarmRepository: AlarmRepository {
  private enum StorageKey {
    static let alarms = "lakshya.alarms"
    static let activeTimer = "lakshya.activeTimer"
    static let timerConfiguration = "lakshya.timerConfiguration"
  }

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadSnapshot() -> AlarmSnapshot {
    let alarms = loadValue(forKey: StorageKey.alarms, defaultValue: [Alarm]())
    let activeTimer = loadOptionalValue(forKey: StorageKey.activeTimer, type: CountdownTimer.self)
    let timerConfiguration = loadValue(
      forKey: StorageKey.timerConfiguration,
      defaultValue: TimerConfiguration.default
    )

    return AlarmSnapshot(
      alarms: alarms,
      activeTimer: activeTimer,
      timerConfiguration: timerConfiguration
    )
  }

  func saveAlarms(_ alarms: [Alarm]) {
    saveValue(alarms, forKey: StorageKey.alarms)
  }

  func saveActiveTimer(_ timer: CountdownTimer?) {
    guard let timer else {
      defaults.removeObject(forKey: StorageKey.activeTimer)
      return
    }

    saveValue(timer, forKey: StorageKey.activeTimer)
  }

  func saveTimerConfiguration(_ configuration: TimerConfiguration) {
    saveValue(configuration, forKey: StorageKey.timerConfiguration)
  }

  private func loadValue<T: Decodable>(forKey key: String, defaultValue: T) -> T {
    guard let value = loadOptionalValue(forKey: key, type: T.self) else {
      return defaultValue
    }

    return value
  }

  private func loadOptionalValue<T: Decodable>(forKey key: String, type: T.Type) -> T? {
    guard let data = defaults.data(forKey: key) else {
      return nil
    }

    return try? JSONDecoder().decode(T.self, from: data)
  }

  private func saveValue<T: Encodable>(_ value: T, forKey key: String) {
    guard let data = try? JSONEncoder().encode(value) else {
      return
    }

    defaults.set(data, forKey: key)
  }
}
