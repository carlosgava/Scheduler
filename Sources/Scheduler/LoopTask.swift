//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

extension Scheduler {
    public func `do`(
        mode: RunLoop.Mode = .common,
        action: @escaping (Task) -> Void
    ) -> Task {
        return LoopTask(plan: self, mode: mode, action: action)
    }

    public func `do`(
        mode: RunLoop.Mode = .common,
        action: @escaping () -> Void
    ) -> Task {
        return self.do(mode: mode) { _ in
            action()
        }
    }
}

private final class LoopTask: Task {
    var timer: Timer!

    init(
        plan: Scheduler,
        mode: RunLoop.Mode,
        action: @escaping (Task) -> Void
    ) {
        super.init(plan: plan, queue: nil) { (task) in
            guard let task = task as? LoopTask, let timer = task.timer else { return }
            timer.fireDate = Date()
        }

        timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, Date.distantFuture.timeIntervalSinceReferenceDate, .greatestFiniteMagnitude, 0, 0, { [weak self] _ in
            guard let self = self else { return }
            action(self)
        })

        RunLoop.current.add(timer, forMode: mode)
    }

    deinit {
        timer.invalidate()
    }
}
