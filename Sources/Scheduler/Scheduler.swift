//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public struct Scheduler: Sequence {
    private var seq: AnySequence<Interval>

    private init<S>(_ sequence: S) where S: Sequence, S.Element == Interval {
        seq = AnySequence(sequence)
    }

    public func makeIterator() -> AnyIterator<Interval> {
        return seq.makeIterator()
    }

    public func `do`(
        queue: DispatchQueue,
        action: @escaping (Task) -> Void
    ) -> Task {
        return Task(plan: self, queue: queue, action: action)
    }

    public func `do`(
        queue: DispatchQueue,
        action: @escaping () -> Void
    ) -> Task {
        return self.do(queue: queue, action: { (_) in action() })
    }
}

extension Scheduler {
    public static func make<I>(
        _ makeUnderlyingIterator: @escaping () -> I
    ) -> Scheduler where I: IteratorProtocol, I.Element == Interval {
        return Scheduler(AnySequence(makeUnderlyingIterator))
    }

    public static func of(_ intervals: Interval...) -> Scheduler {
        return Scheduler.of(intervals)
    }

    public static func of<S>(_ intervals: S) -> Scheduler where S: Sequence, S.Element == Interval {
        return Scheduler(intervals)
    }
}

extension Scheduler {
    public static func make<I>(
        _ makeUnderlyingIterator: @escaping () -> I
    ) -> Scheduler where I: IteratorProtocol, I.Element == Date {
        return Scheduler.make { () -> AnyIterator<Interval> in
            var iterator = makeUnderlyingIterator()
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard let next = iterator.next() else { return nil }
                defer { prev = next }
                return next.interval(since: prev)
            }
        }
    }

    public static func of(_ dates: Date...) -> Scheduler {
        return Scheduler.of(dates)
    }

    public static func of<S>(_ sequence: S) -> Scheduler where S: Sequence, S.Element == Date {
        return Scheduler.make(sequence.makeIterator)
    }

    public var dates: AnySequence<Date> {
        return AnySequence { () -> AnyIterator<Date> in
            let iterator = self.makeIterator()
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard let interval = iterator.next() else { return nil }
                // swiftlint:disable shorthand_operator
                prev = prev + interval
                return prev
            }
        }
    }
}

extension Scheduler {
    public static var distantPast: Scheduler {
        return Scheduler.of(Date.distantPast)
    }

    public static var distantFuture: Scheduler {
        return Scheduler.of(Date.distantFuture)
    }

    public static var never: Scheduler {
        return Scheduler.make {
            AnyIterator<Interval> { nil }
        }
    }
}

extension Scheduler {
    public func concat(_ plan: Scheduler) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Interval> in
            let i0 = self.makeIterator()
            let i1 = plan.makeIterator()
            return AnyIterator {
                if let interval = i0.next() { return interval }
                return i1.next()
            }
        }
    }

    public func merge(_ plan: Scheduler) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Date> in
            let i0 = self.dates.makeIterator()
            let i1 = plan.dates.makeIterator()

            var buf0: Date!
            var buf1: Date!

            return AnyIterator<Date> {
                if buf0 == nil { buf0 = i0.next() }
                if buf1 == nil { buf1 = i1.next() }

                var d: Date!
                if let d0 = buf0, let d1 = buf1 {
                    d = Swift.min(d0, d1)
                } else {
                    d = buf0 ?? buf1
                }

                if d == nil { return d }

                if d == buf0 { buf0 = nil; return d }
                if d == buf1 { buf1 = nil }
                return d
            }
        }
    }

    public func first(_ count: Int) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Interval> in
            let iterator = self.makeIterator()
            var num = 0
            return AnyIterator {
                guard num < count, let interval = iterator.next() else { return nil }
                num += 1
                return interval
            }
        }
    }

    public func until(_ date: Date) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Date> in
            let iterator = self.dates.makeIterator()
            return AnyIterator {
                guard let next = iterator.next(), next < date else {
                    return nil
                }
                return next
            }
        }
    }

    public static var now: Scheduler {
        return Scheduler.of(0.nanosecond)
    }

    public static func after(_ delay: Interval) -> Scheduler {
        return Scheduler.of(delay)
    }

    public static func after(_ delay: Interval, repeating interval: Interval) -> Scheduler {
        return Scheduler.after(delay).concat(Scheduler.every(interval))
    }

    public static func at(_ date: Date) -> Scheduler {
        return Scheduler.of(date)
    }

    public static func every(_ interval: Interval) -> Scheduler {
        return Scheduler.make {
            AnyIterator { interval }
        }
    }

    public static func every(_ period: Period) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Interval> in
            let calendar = Calendar.gregorian
            var prev: Date!
            return AnyIterator {
                prev = prev ?? Date()
                guard
                    let next = calendar.date(
                        byAdding: period.asDateComponents(),
                        to: prev)
                else {
                    return nil
                }
                defer { prev = next }
                return next.interval(since: prev)
            }
        }
    }

    public static func every(_ period: String) -> Scheduler {
        guard let p = Period(period) else {
            return Scheduler.never
        }
        return Scheduler.every(p)
    }
}

extension Scheduler {
    public struct DateMiddleware {
        fileprivate let plan: Scheduler

        public func at(_ time: Time) -> Scheduler {
            if plan.isNever() { return .never }

            var interval = time.intervalSinceStartOfDay
            return Scheduler.make { () -> AnyIterator<Interval> in
                let it = self.plan.makeIterator()
                return AnyIterator {
                    if let next = it.next() {
                        defer { interval = 0.nanoseconds }
                        return next + interval
                    }
                    return nil
                }
            }
        }

        public func at(_ time: String) -> Scheduler {
            if plan.isNever() { return .never }
            guard let time = Time(time) else {
                return .never
            }
            return at(time)
        }

        public func at(_ time: Int...) -> Scheduler {
            return self.at(time)
        }

        public func at(_ time: [Int]) -> Scheduler {
            if plan.isNever() || time.isEmpty { return .never }

            let hour = time[0]
            let minute = time.count > 1 ? time[1] : 0
            let second = time.count > 2 ? time[2] : 0
            let nanosecond = time.count > 3 ? time[3]: 0

            guard let time = Time(
                hour: hour,
                minute: minute,
                second: second,
                nanosecond: nanosecond
            ) else {
                return Scheduler.never
            }
            return at(time)
        }
    }

    public static func every(_ week: Week) -> DateMiddleware {
        let plan = Scheduler.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date?
            return AnyIterator<Date> {
                if let d = date {
                    date = calendar.date(byAdding: .day, value: 7, to: d)
                } else if Date().is(week) {
                    date = Date().startOfToday
                } else {
                    let components = week.asDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    public static func every(_ weekdays: Week...) -> DateMiddleware {
        return Scheduler.every(weekdays)
    }

    public static func every(_ weekdays: [Week]) -> DateMiddleware {
        guard !weekdays.isEmpty else { return .init(plan: .never) }

        var plan = every(weekdays[0]).plan
        for weekday in weekdays.dropFirst() {
            plan = plan.merge(Scheduler.every(weekday).plan)
        }
        return DateMiddleware(plan: plan)
    }

    public static func every(_ month: Month) -> DateMiddleware {
        let plan = Scheduler.make { () -> AnyIterator<Date> in
            let calendar = Calendar.gregorian
            var date: Date?
            return AnyIterator<Date> {
                if let d = date {
                    date = calendar.date(byAdding: .year, value: 1, to: d)
                } else if Date().is(month) {
                    date = Date().startOfToday
                } else {
                    let components = month.asDateComponents()
                    date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
                }
                return date
            }
        }
        return DateMiddleware(plan: plan)
    }

    public static func every(_ mondays: Month...) -> DateMiddleware {
        return Scheduler.every(mondays)
    }

    public static func every(_ mondays: [Month]) -> DateMiddleware {
        guard !mondays.isEmpty else { return .init(plan: .never) }

        var plan = every(mondays[0]).plan
        for monday in mondays.dropFirst() {
            plan = plan.merge(Scheduler.every(monday).plan)
        }
        return DateMiddleware(plan: plan)
    }
}

extension Scheduler {
    public func isNever() -> Bool {
        return seq.makeIterator().next() == nil
    }
}

extension Scheduler {
    public func offset(by interval: @autoclosure @escaping () -> Interval?) -> Scheduler {
        return Scheduler.make { () -> AnyIterator<Interval> in
            let it = self.makeIterator()
            return AnyIterator {
                if let next = it.next() {
                    return next + (interval() ?? 0.second)
                }
                return nil
            }
        }
    }
}
