import Foundation

extension Date {
    /// Creates a Date from a Unix timestamp
    init(unixTimestamp: Int) {
        self.init(timeIntervalSince1970: TimeInterval(unixTimestamp))
    }

    /// Formats as hour string, e.g. "2 PM"
    func formattedHour(timezoneOffset: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h a"
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: self)
    }

    /// Formats as short time, e.g. "6:30 AM"
    func formattedTime(timezoneOffset: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: self)
    }

    /// Formats as day of week, e.g. "Monday"
    func formattedDayOfWeek(timezoneOffset: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: self)
    }

    /// Formats as short day of week, e.g. "Mon"
    func formattedShortDay(timezoneOffset: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: self)
    }

    /// Formats as full date, e.g. "Monday, March 24"
    func formattedFullDate(timezoneOffset: Int = 0) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone(secondsFromGMT: timezoneOffset)
        return formatter.string(from: self)
    }

    /// Checks if the given unix timestamp represents daytime
    static func isDaytime(currentDt: Int, sunrise: Int, sunset: Int) -> Bool {
        return currentDt >= sunrise && currentDt < sunset
    }
}

extension Int {
    /// Converts Unix timestamp to a Date
    var asDate: Date {
        Date(unixTimestamp: self)
    }
}
