//
//  Created by Carlos Henrique Gava on 05/02/19.
//
import Foundation

extension Double {
    func clampedToInt() -> Int {
        if self >= Double(Int.max) { return Int.max }
        if self <= Double(Int.min) { return Int.min }
        return Int(self)
    }
}

extension Int {
    func clampedAdding(_ other: Int) -> Int {
        return (Double(self) + Double(other)).clampedToInt()
    }
}

extension Locale {
    static let posix = Locale(identifier: "en_US_POSIX")
}

extension Calendar {
    static let gregorian: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.posix
        return cal
    }()
}

extension Date {
    var startOfToday: Date {
        return Calendar.gregorian.startOfDay(for: self)
    }
}

extension NSLocking {
    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try body()
    }
    @inline(__always)
    func withLockVoid(_ body: () throws -> Void) rethrows {
        lock(); defer { unlock() }
        try body()
    }
}
