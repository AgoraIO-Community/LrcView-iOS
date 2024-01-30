//
//  DataStructs.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/14.
//

import Foundation

struct Queue<T> {
    private var elements: [T] = []
    
    mutating func enqueue(_ element: T) {
        elements.append(element)
    }
    
    mutating func dequeue() -> T? {
        return elements.isEmpty ? nil : elements.removeFirst()
    }
    
    var isEmpty: Bool {
        return elements.isEmpty
    }
    
    var count: Int {
        return elements.count
    }
    
    func peek() -> T? {
        return elements.first
    }
    
    mutating func removeAll() {
        elements.removeAll()
    }
    
    func getAll() -> [T] {
        return elements
    }
    
    mutating func reset(newElements: [T]) {
        elements = newElements
    }
}

/// Dictionary for safe, use rwlock
class SafeDictionary<T_KEY: Hashable, T_VALUE: Hashable> {
    private var dict: Dictionary<T_KEY, T_VALUE> = Dictionary()
    private var rwlock = pthread_rwlock_t()
    private let logTag = "SafeDictionary"
    
    init() {
        Log.debug(text: "init", tag: logTag)
        pthread_rwlock_init(&rwlock, nil)
    }
    
    deinit {
        Log.debug(text: "deinit", tag: logTag)
        pthread_rwlock_destroy(&rwlock)
    }
    
    func set(value: T_VALUE, forkey: T_KEY) {
        pthread_rwlock_wrlock(&rwlock)
        dict[forkey] = value
        pthread_rwlock_unlock(&rwlock)
    }
    
    func getValue(forkey: T_KEY) -> T_VALUE? {
        pthread_rwlock_rdlock(&rwlock)
        let value = dict[forkey]
        pthread_rwlock_unlock(&rwlock)
        return value
    }
    
    func removeValue(forkey: T_KEY) {
        pthread_rwlock_wrlock(&rwlock)
        dict.removeValue(forKey: forkey)
        pthread_rwlock_unlock(&rwlock)
    }
}

