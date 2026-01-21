//
//  UnfairLock.swift
//  Data
//
//  Created by Kai Lee on 1/21/26.
//

import Foundation

final class UnfairLock {
    private var _lock = os_unfair_lock()

    func lock() {
        os_unfair_lock_lock(&_lock)
    }

    func unlock() {
        os_unfair_lock_unlock(&_lock)
    }
}
