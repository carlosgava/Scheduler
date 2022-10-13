//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public enum Week: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public func asDateComponents(_ timeZone: TimeZone = .current) -> DateComponents {
        return DateComponents(
            calendar: Calendar.gregorian,
            timeZone: timeZone,
            weekday: rawValue)
    }
}

extension Date {
    public func `is`(_ weekday: Week, in timeZone: TimeZone = .current) -> Bool {
        var cal = Calendar.gregorian
        cal.timeZone = timeZone
        return cal.component(.weekday, from: self) == weekday.rawValue
    }
}

extension Week: CustomStringConvertible {
    public var description: String {
        return "Week: \(Calendar.gregorian.weekdaySymbols[rawValue - 1])"
    }
}

extension Week: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}
