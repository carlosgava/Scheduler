//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

extension TaskCenter {
    private class TaskBox: Hashable {
        weak var task: Task?
        let hash: Int

        init(_ task: Task) {
            self.task = task
            self.hash = task.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hash)
        }

        static func == (lhs: TaskBox, rhs: TaskBox) -> Bool {
            return lhs.task == rhs.task
        }
    }
}

private let _default = TaskCenter()

open class TaskCenter {
    private let lock = NSLock()
    private var tags: [String: Set<TaskBox>] = [:]
    private var tasks: [TaskBox: Set<String>] = [:]

    open class var `default`: TaskCenter {
        return _default
    }
    
    public init() { }

    open func add(_ task: Task) {
        task.addToTaskCenter(self)
    }
    
    func addSimply(_ task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            self.tasks[box] = []
        }
    }
    
    func removeSimply(_ task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            guard let tags = self.tasks[box] else {
                return
            }
            
            self.tasks[box] = nil
            for tag in tags {
                self.tags[tag]?.remove(box)
                if self.tags[tag]?.count == 0 {
                    self.tags[tag] = nil
                }
            }
        }
    }

    open func addTag(_ tag: String, to task: Task) {
        addTags([tag], to: task)
    }

    open func addTags(_ tags: [String], to task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            guard self.tasks[box] != nil else {
                return
            }
            
            for tag in tags {
                self.tasks[box]?.insert(tag)
                if self.tags[tag] == nil {
                    self.tags[tag] = []
                }
                self.tags[tag]?.insert(box)
            }
        }
    }

    open func removeTag(_ tag: String, from task: Task) {
        removeTags([tag], from: task)
    }

    open func removeTags(_ tags: [String], from task: Task) {
        lock.withLockVoid {
            let box = TaskBox(task)
            guard self.tasks[box] != nil else {
                return
            }
            
            for tag in tags {
                self.tasks[box]?.remove(tag)
                self.tags[tag]?.remove(box)
                if self.tags[tag]?.count == 0 {
                    self.tags[tag] = nil
                }
            }
        }
    }

    open func tags(forTask task: Task) -> [String] {
        return lock.withLock {
            Array(tasks[TaskBox(task)] ?? [])
        }
    }

    open func tasks(forTag tag: String) -> [Task] {
        return lock.withLock {
            tags[tag]?.compactMap { $0.task } ?? []
        }
    }

    open var allTasks: [Task] {
        return lock.withLock {
            tasks.compactMap { $0.key.task }
        }
    }

    open var allTags: [String] {
        return lock.withLock {
            tags.map { $0.key }
        }
    }

    open func removeAll() {
        allTasks.forEach {
            $0.removeFromTaskCenter()
        }
    }

    open func suspend(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.suspend() }
    }

    open func resume(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.resume() }
    }

    open func cancel(byTag tag: String) {
        tasks(forTag: tag).forEach { $0.cancel() }
    }
}
