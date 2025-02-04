import ComposableArchitecture
import Foundation

public extension DateFormatter {
  static let IDStoreHashDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}

public extension DateComponentsFormatter {
  /// Formatter to handle Twitter
  static func tweetDateFormatter(_ calendar: Calendar = .current) -> DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.calendar = calendar
    formatter.allowedUnits = [.month, .day, .hour, .minute]
    formatter.unitsStyle = .short
    formatter.maximumUnitCount = 1
    return formatter
  }
}

public extension Date.FormatStyle {
  /// Format to display only the day and a medium format month -> 28 Okt.
  static let dateWithoutYear: Self = .dateTime
    .day(.defaultDigits)
    .month(.abbreviated)

  static let medium = Self(
    date: .abbreviated,
    time: .omitted,
    locale: .autoupdatingCurrent
  )

  static let localeAwareShortDate: Self = {
    @Dependency(\.timeZone) var timezone
    return Self(
      date: .abbreviated,
      time: .omitted,
      locale: .autoupdatingCurrent,
      timeZone: timezone
    )
  }()

  static let localeAwareShortTime = Self(
    date: .omitted,
    time: .shortened,
    locale: .autoupdatingCurrent,
    timeZone: .germany
  )

  static func chatTime(_ cal: Calendar = .autoupdatingCurrent) -> Self {
    var format = Self.dateTime
      .hour(.twoDigits(amPM: .abbreviated))
      .minute(.twoDigits)
    format.locale = .autoupdatingCurrent
    format.timeZone = cal.timeZone
    format.calendar = cal
    return format
  }
}
