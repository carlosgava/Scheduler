//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public struct Period {
    public private(set) var years: Int
    public private(set) var months: Int
    public private(set) var days: Int
    public private(set) var hours: Int
    public private(set) var minutes: Int
    public private(set) var seconds: Int
    public private(set) var nanoseconds: Int

    public init(years: Int = 0, months: Int = 0, days: Int = 0,
                hours: Int = 0, minutes: Int = 0, seconds: Int = 0,
                nanoseconds: Int = 0) {
        self.years = years
        self.months = months
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }

    private static let quantifiers: Atomic<[String: Int]> = Atomic([
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12
        ])

    public static func registerQuantifier(_ word: String, for number: Int) {
        quantifiers.writeVoid { $0[word] = number }
    }

    public init?(_ string: String) {
        var str = string
        for (word, number) in Period.quantifiers.read({ $0 }) {
            str = str.replacingOccurrences(of: word, with: "\(number)")
        }

        // swiftlint:disable force_try
        let regexp = try! NSRegularExpression(pattern: "( and |, )")
        let mark: Character = "秋"
        str = regexp.stringByReplacingMatches(
            in: str,
            range: NSRange(str.startIndex..., in: str),
            withTemplate: String(mark)
        )

        var period = 0.year
        for pair in str.split(separator: mark).map({ $0.split(separator: " ") }) {
            guard
                pair.count == 2,
                let number = Int(pair[0])
            else {
                return nil
            }

            var unit = pair[1]
            if unit.last == "s" { unit.removeLast() }
            switch unit {
            case "year":            period = period + number.years
            case "month":           period = period + number.months
            case "day":             period = period + number.days
            case "week":            period = period + (number * 7).days
            case "hour":            period = period + number.hours
            case "minute":          period = period + number.minutes
            case "second":          period = period + number.second
            case "nanosecond":      period = period + number.nanosecond
            default:                break
            }
        }
        self = period
    }

    public func adding(_ other: Period) -> Period {
        return Period(
            years: years.clampedAdding(other.years),
            months: months.clampedAdding(other.months),
            days: days.clampedAdding(other.days),
            hours: hours.clampedAdding(other.hours),
            minutes: minutes.clampedAdding(other.minutes),
            seconds: seconds.clampedAdding(other.seconds),
            nanoseconds: nanoseconds.clampedAdding(other.nanoseconds))
    }

    public func adding(_ interval: Interval) -> Period {
        return Period(
            years: years, months: months, days: days,
            hours: hours, minutes: minutes, seconds: seconds,
            nanoseconds: nanoseconds.clampedAdding(interval.nanoseconds.clampedToInt()))
            .tidied(to: .day)
    }

    public static func + (lhs: Period, rhs: Period) -> Period {
        return lhs.adding(rhs)
    }

    public static func + (lhs: Period, rhs: Interval) -> Period {
        return lhs.adding(rhs)
    }

    public enum TideLevel {
        case day, hour, minute, second, nanosecond
    }

    public func tidied(to level: TideLevel) -> Period {
        var period = self

        if case .nanosecond = level { return period }

        if period.nanoseconds.magnitude >= UInt(1.second.nanoseconds) {
            period.seconds += period.nanoseconds / Int(1.second.nanoseconds)
            period.nanoseconds %= Int(1.second.nanoseconds)
        }
        if case .second = level { return period }

        if period.seconds.magnitude >= 60 {
            period.minutes += period.seconds / 60
            period.seconds %= 60
        }
        if case .minute = level { return period }

        if period.minutes.magnitude >= 60 {
            period.hours += period.minutes / 60
            period.minutes %= 60
        }
        if case .hour = level { return period }

        if period.hours.magnitude >= 24 {
            period.days += period.hours / 24
            period.hours %= 24
        }
        return period
    }

    public func asDateComponents(_ timeZone: TimeZone = .current) -> DateComponents {
        return DateComponents(
            calendar: Calendar.gregorian,
            timeZone: timeZone,
            year: years,
            month: months,
            day: days,
            hour: hours,
            minute: minutes,
            second: seconds,
            nanosecond: nanoseconds
        )
    }
}

extension Date {
    public func adding(_ period: Period) -> Date {
        return Calendar.gregorian.date(byAdding: period.asDateComponents(), to: self) ?? .distantFuture
    }

    public static func + (lhs: Date, rhs: Period) -> Date {
        return lhs.adding(rhs)
    }
}

extension Int {
    public var years: Period {
        return Period(years: self)
    }

    public var year: Period {
        return years
    }

    public var months: Period {
        return Period(months: self)
    }

    public var month: Period {
        return months
    }
}

extension Period: CustomStringConvertible {
    public var description: String {
        let period = tidied(to: .day)
        var desc = "Period:"
        if period.years != 0 { desc += " \(period.years) year(s)" }
        if period.months != 0 { desc += " \(period.months) month(s)" }
        if period.days != 0 { desc += " \(period.days) day(s)" }
        if period.hours != 0 { desc += " \(period.hours) hour(s)" }
        if period.minutes != 0 { desc += " \(period.minutes) minute(s)" }
        if period.seconds != 0 { desc += " \(period.seconds) second(s)" }
        if period.nanoseconds != 0 { desc += " \(period.nanoseconds) nanosecond(s)" }
        return desc
    }
}

extension Period: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}
