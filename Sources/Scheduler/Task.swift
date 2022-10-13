//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

public struct ActionKey {
    fileprivate let bagKey: BagKey
}

extension BagKey {
    fileprivate func asActionKey() -> ActionKey {
        return ActionKey(bagKey: self)
    }
}

open class Task {
    // MARK: - Private properties
    
    private let _lock = NSLock()

    private var _iterator: AnyIterator<Interval>
    private let _timer: DispatchSourceTimer

    private var _actions = Bag<Action>()

    private var _suspensionCount = 0
    private var _executionCount = 0

    private var _executionDates: [Date]?
    private var _estimatedNextExecutionDate: Date?

    private var _taskCenter: TaskCenter?
    private var _tags: Set<String> = []

    // MARK: - Public properties
    public let id = UUID()
    public typealias Action = (Task) -> Void
    public let creationDate = Date()
    open var firstExecutionDate: Date? {
        return _lock.withLock { _executionDates?.first }
    }

    open var lastExecutionDate: Date? {
        return _lock.withLock { _executionDates?.last }
    }

    open var executionDates: [Date]? {
        return _lock.withLock { _executionDates }
    }

    open var estimatedNextExecutionDate: Date? {
        return _lock.withLock { _estimatedNextExecutionDate }
    }

    public var executionCount: Int {
        return _lock.withLock {
            _executionCount
        }
    }

    public var suspensionCount: Int {
        return _lock.withLock {
            _suspensionCount
        }
    }

    public var actionCount: Int {
        return _lock.withLock {
            _actions.count
        }
    }

    public var isCancelled: Bool {
        return _lock.withLock {
            _timer.isCancelled
        }
    }

    open var taskCenter: TaskCenter? {
        return _lock.withLock { _taskCenter }
    }


    // MARK: - Init
    init(
        plan: Scheduler,
        queue: DispatchQueue?,
        action: @escaping (Task) -> Void
    ) {
        _iterator = plan.makeIterator()
        _timer = DispatchSource.makeTimerSource(queue: queue)

        _actions.append(action)

        _timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.elapse()
        }

        if let interval = _iterator.next(), !interval.isNegative {
            _timer.schedule(after: interval)
            _estimatedNextExecutionDate = Date().adding(interval)
        }

        _timer.resume()

        TaskCenter.default.add(self)
    }

    deinit {
        while _suspensionCount > 0 {
            _timer.resume()
            _suspensionCount -= 1
        }

        self.removeFromTaskCenter()
    }

    private func elapse() {
        scheduleNextExecution()
        executeNow()
    }

    private func scheduleNextExecution() {
        _lock.withLockVoid {
            let now = Date()
            var estimated = _estimatedNextExecutionDate ?? now
            repeat {
                guard let interval = _iterator.next(), !interval.isNegative else {
                    _estimatedNextExecutionDate = nil
                    return
                }
                estimated = estimated.adding(interval)
            } while (estimated < now)

            _estimatedNextExecutionDate = estimated
            _timer.schedule(after: _estimatedNextExecutionDate!.interval(since: now))
        }
    }

    open func executeNow() {
        let actions = _lock.withLock { () -> Bag<Task.Action> in
            let now = Date()
            if _executionDates == nil {
                _executionDates = [now]
            } else {
                _executionDates?.append(now)
            }
            _executionCount += 1
            return _actions
        }
        actions.forEach { $0(self) }
    }

    // MARK: - Features
    public func reschedule(_ new: Scheduler) {
        _lock.lock()
        if _timer.isCancelled {
            _lock.unlock()
            return
        }
        
        _iterator = new.makeIterator()
        _lock.unlock()
        scheduleNextExecution()
    }

    public func suspend() {
        _lock.withLockVoid {
            if _timer.isCancelled { return }

            if _suspensionCount < UInt64.max {
                _timer.suspend()
                _suspensionCount += 1
            }
        }
    }

    public func resume() {
        _lock.withLockVoid {
            if _timer.isCancelled { return }

            if _suspensionCount > 0 {
                _timer.resume()
                _suspensionCount -= 1
            }
        }
    }

    public func cancel() {
        _lock.withLockVoid {
            _timer.cancel()
            _suspensionCount = 0
        }
    }

    @discardableResult
    public func addAction(_ action: @escaping (Task) -> Void) -> ActionKey {
        return _lock.withLock {
            return _actions.append(action).asActionKey()
        }
    }

    public func removeAction(byKey key: ActionKey) {
        _lock.withLockVoid {
            _ = _actions.removeValue(for: key.bagKey)
        }
    }

    public func removeAllActions() {
        _lock.withLockVoid {
            _actions.removeAll()
        }
    }
    
    func addToTaskCenter(_ center: TaskCenter) {
        _lock.lock(); defer { _lock.unlock() }
        
        if _taskCenter === center { return }
        
        let c = _taskCenter
        _taskCenter = center
        c?.removeSimply(self)
        center.addSimply(self)
    }
    
    public func removeFromTaskCenter() {
        _lock.lock(); defer { _lock.unlock() }
        
        guard let center = self._taskCenter else {
            return
        }
        _taskCenter = nil
        center.removeSimply(self)
    }
}

extension Task: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
}
