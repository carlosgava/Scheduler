//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public enum Month {
    case january(Int)
    case february(Int)
    case march(Int)
    case april(Int)
    case may(Int)
    case june(Int)
    case july(Int)
    case august(Int)
    case september(Int)
    case october(Int)
    case november(Int)
    case december(Int)

    public func asDateComponents(_ timeZone: TimeZone = .current) -> DateComponents {
        var month, day: Int
        switch self {
        case .january(let n):       month = 1; day = n
        case .february(let n):      month = 2; day = n
        case .march(let n):         month = 3; day = n
        case .april(let n):         month = 4; day = n
        case .may(let n):           month = 5; day = n
        case .june(let n):          month = 6; day = n
        case .july(let n):          month = 7; day = n
        case .august(let n):        month = 8; day = n
        case .september(let n):     month = 9; day = n
        case .october(let n):       month = 10; day = n
        case .november(let n):      month = 11; day = n
        case .december(let n):      month = 12; day = n
        }
        return DateComponents(
            calendar: Calendar.gregorian,
            timeZone: timeZone,
            month: month,
            day: day)
    }
}

extension Date {
    public func `is`(_ monthday: Month, in timeZone: TimeZone = .current) -> Bool {
        let components = monthday.asDateComponents(timeZone)

        let m = Calendar.gregorian.component(.month, from: self)
        let d = Calendar.gregorian.component(.day, from: self)
        return m == components.month && d == components.day
    }
}

extension Month: CustomStringConvertible {
    public var description: String {
        let components = asDateComponents()

        let m = components.month!
        let d = components.day!

        let ms = Calendar.gregorian.monthSymbols[m - 1]

        let fmt = NumberFormatter()
        fmt.locale = Locale.posix
        if #available(OSX 10.11, *) {
            fmt.numberStyle = .ordinal
        } else {
            // Fallback on earlier versions
        }
        let ds = fmt.string(from: NSNumber(value: d))!

        return "Month: \(ms) \(ds)"
    }
}

extension Month: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}
