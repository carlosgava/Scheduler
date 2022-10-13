//
//  Created by Carlos Henrique Gava on 05/02/19.
//

import Foundation

struct BagKey: Equatable {
    private let i: UInt64
    struct Gen {
        private var key = BagKey(i: 0)
        init() { }
        mutating func next() -> BagKey {
            defer { key = BagKey(i: key.i + 1) }
            return key
        }
    }
}

struct Bag<Element> {
    private typealias Entry = (key: BagKey, val: Element)

    private var keyGen = BagKey.Gen()
    private var entries: [Entry] = []

    @discardableResult
    mutating func append(_ new: Element) -> BagKey {
        let key = keyGen.next()

        let entry = (key: key, val: new)
        entries.append(entry)

        return key
    }

    func value(for key: BagKey) -> Element? {
        return entries.first(where: { $0.key == key })?.val
    }

    @discardableResult
    mutating func removeValue(for key: BagKey) -> Element? {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: i).val
        }
        return nil
    }

    mutating func removeAll() {
        entries.removeAll()
    }

    var count: Int {
        return entries.count
    }
}

extension Bag: Sequence {
    @inline(__always)
    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.val
        }
    }
}
