//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

final class Atomic<T> {
    private var val: T
    private let lock = NSLock()

    @inline(__always)
    init(_ value: T) {
        self.val = value
    }

    @inline(__always)
    func read<U>(_ body: (T) -> U) -> U {
        return lock.withLock { body(val) }
    }

    @inline(__always)
    func readVoid(_ body: (T) -> Void) {
        lock.withLockVoid { body(val) }
    }

    @inline(__always)
    func write<U>(_ body: (inout T) -> U) -> U {
        return lock.withLock { body(&val) }
    }

    @inline(__always)
    func writeVoid(_ body: (inout T) -> Void) {
        lock.withLockVoid { body(&val) }
    }
}
