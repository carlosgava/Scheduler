//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public struct Interval {
    public let nanoseconds: Double
    public init(nanoseconds: Double) {
        self.nanoseconds = nanoseconds
    }
}

extension Interval: Hashable { }

extension Interval {
    public var isNegative: Bool {
        return nanoseconds < 0
    }

    public var abs: Interval {
        return Interval(nanoseconds: Swift.abs(nanoseconds))
    }

    public var negated: Interval {
        return Interval(nanoseconds: -nanoseconds)
    }
}

extension Interval: CustomStringConvertible {
    public var description: String {
        return "Interval: \(nanoseconds.clampedToInt()) nanosecond(s)"
    }
}

extension Interval: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}

// MARK: - Comparar

extension Interval: Comparable {
    public func compare(_ other: Interval) -> ComparisonResult {
        let d = nanoseconds - other.nanoseconds

        if d < 0 { return .orderedAscending }
        if d > 0 { return .orderedDescending }
        return .orderedSame
    }

    public static func < (lhs: Interval, rhs: Interval) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }

    public func isLonger(than other: Interval) -> Bool {
        return abs > other.abs
    }

    public func isShorter(than other: Interval) -> Bool {
        return abs < other.abs
    }
}

// MARK: - Adicionar ou Subtrair

extension Interval {
    public func multiplying(by multiplier: Double) -> Interval {
        return Interval(nanoseconds: nanoseconds * multiplier)
    }

    public func adding(_ other: Interval) -> Interval {
        return Interval(nanoseconds: nanoseconds + other.nanoseconds)
    }
}

// MARK: - Operadores
extension Interval {
    public static func * (lhs: Interval, rhs: Double) -> Interval {
        return lhs.multiplying(by: rhs)
    }

    public static func + (lhs: Interval, rhs: Interval) -> Interval {
        return lhs.adding(rhs)
    }

    public static func - (lhs: Interval, rhs: Interval) -> Interval {
        return lhs.adding(rhs.negated)
    }

    public static func += (lhs: inout Interval, rhs: Interval) {
        lhs = lhs.adding(rhs)
    }

    public prefix static func - (interval: Interval) -> Interval {
        return interval.negated
    }
}

// MARK: - Implementos
extension Interval {
    public func asNanoseconds() -> Double {
        return nanoseconds
    }

    public func asMicroseconds() -> Double {
        return nanoseconds / pow(10, 3)
    }

    public func asMilliseconds() -> Double {
        return nanoseconds / pow(10, 6)
    }

    public func asSeconds() -> Double {
        return nanoseconds / pow(10, 9)
    }

    public func asMinutes() -> Double {
        return asSeconds() / 60
    }

    public func asHours() -> Double {
        return asMinutes() / 60
    }

    public func asDays() -> Double {
        return asHours() / 24
    }

    public func asWeeks() -> Double {
        return asDays() / 7
    }
}

public protocol IntervalConvertible {
    var nanoseconds: Interval { get }
}

extension Int: IntervalConvertible {
    public var nanoseconds: Interval {
        return Interval(nanoseconds: Double(self))
    }
}

extension Double: IntervalConvertible {
    public var nanoseconds: Interval {
        return Interval(nanoseconds: self)
    }
}

extension IntervalConvertible {
    public var nanosecond: Interval {
        return nanoseconds
    }

    public var microsecond: Interval {
        return microseconds
    }

    public var microseconds: Interval {
        return nanoseconds * pow(10, 3)
    }

    public var millisecond: Interval {
        return milliseconds
    }

    public var milliseconds: Interval {
        return microseconds * pow(10, 3)
    }

    public var second: Interval {
        return seconds
    }

    public var seconds: Interval {
        return milliseconds * pow(10, 3)
    }

    public var minute: Interval {
        return minutes
    }

    public var minutes: Interval {
        return seconds * 60
    }

    public var hour: Interval {
        return hours
    }

    public var hours: Interval {
        return minutes * 60
    }

    public var day: Interval {
        return days
    }

    public var days: Interval {
        return hours * 24
    }

    public var week: Interval {
        return weeks
    }

    public var weeks: Interval {
        return days * 7
    }
}

// MARK: - Date
extension Date {
    public var intervalSinceNow: Interval {
        return timeIntervalSinceNow.seconds
    }

    public func interval(since date: Date) -> Interval {
        return timeIntervalSince(date).seconds
    }

    public func adding(_ interval: Interval) -> Date {
        return addingTimeInterval(interval.asSeconds())
    }

    public static func + (lhs: Date, rhs: Interval) -> Date {
        return lhs.adding(rhs)
    }
}

// MARK: - DispatchSourceTimer
extension DispatchSourceTimer {
    func schedule(after timeout: Interval) {
        if timeout.isNegative { return }
        let ns = timeout.nanoseconds.clampedToInt()
        schedule(wallDeadline: .now() + DispatchTimeInterval.nanoseconds(ns))
    }
}
