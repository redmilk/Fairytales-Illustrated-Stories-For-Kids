//
//  Publisher+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 22.04.2021.
//

import Combine

extension Publisher where Self.Failure == Never {
    public func assignNoRetain<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] (value) in
            object?[keyPath: keyPath] = value
        }
    }
}

extension Publisher {
    static func empty() -> AnyPublisher<Output, Failure> {
        return Empty().eraseToAnyPublisher()
    }

    static func fail(_ error: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: error).eraseToAnyPublisher()
    }
    
    static func just(output: Output) -> AnyPublisher<Output, Failure> {
        return Just(output).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }
}

public extension Publisher {
    /// Transforms an output value into a new publisher, and flattens the stream of events from these multiple upstream publishers to appear as if they were coming from a single stream of events
    ///
    /// Mapping to a new publisher will cancel the subscription to the previous one, keeping only a single
    /// subscription active along with its event emissions
    ///
    /// - parameter transform: A transform to apply to each emitted value, from which you can return a new Publisher
    ///
    /// - note: This operator is a combination of `map` and `switchToLatest`
    ///
    /// - returns: A publisher emitting the values of the latest inner publisher
    func flatMapLatest<P: Publisher>(_ transform: @escaping (Output) -> P) -> Publishers.SwitchToLatest<P, Publishers.Map<Self, P>> {
        map(transform).switchToLatest()
    }
}

public extension Collection where Element: Publisher {
    /// Merge a collection of publishers with the same output and failure types into a single publisher.
    /// If any of the publishers in the collection fails, the returned publisher will also fail.
    /// The returned publisher will not finish until all of the merged publishers finish.
    ///
    /// - Returns: A type-erased publisher that emits all events from the publishers in the collection.
    func merge() -> AnyPublisher<Element.Output, Element.Failure> {
        Publishers.MergeMany(self).eraseToAnyPublisher()
    }
}

public enum ObjectOwnership {
    /// Keep a strong hold of the object, preventing ARC
    /// from disposing it until its released or has no references.
    case strong

    /// Weakly owned. Does not keep a strong hold of the object,
    /// allowing ARC to dispose it even if its referenced.
    case weak

    /// Unowned. Similar to weak, but implicitly unwrapped so may
    /// crash if the object is released beore being accessed.
    case unowned
}


public extension Publisher where Self.Failure == Never {
    /// Assigns a publisher’s output to a property of an object.
    ///
    /// - parameter keyPath: A key path that indicates the property to assign.
    /// - parameter object: The object that contains the property.
    ///                     The subscriber assigns the object’s property every time
    ///                     it receives a new value.
    /// - parameter ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - returns: An AnyCancellable instance. Call cancel() on this instance when you no longer want
    ///            the publisher to automatically assign the property. Deinitializing this instance
    ///            will also cancel automatic assignment.
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
                                 on object: Root,
                                 ownership: ObjectOwnership = .strong) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath, on: object)
        case .weak:
            return sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
        case .unowned:
            return sink { [unowned object] value in
                object[keyPath: keyPath] = value
            }
        }
    }

    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///   - ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value.
    ///            Deallocation of the result will tear down the subscription stream.
    func assign<Root1: AnyObject, Root2: AnyObject>(
        to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
        and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2,
        ownership: ObjectOwnership = .strong
    ) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath1, on: object1, and: keyPath2, on: object2)
        case .weak:
            return sink { [weak object1, weak object2] value in
                object1?[keyPath: keyPath1] = value
                object2?[keyPath: keyPath2] = value
            }
        case .unowned:
            return sink { [unowned object1, unowned object2] value in
                object1[keyPath: keyPath1] = value
                object2[keyPath: keyPath2] = value
            }
        }
    }

    /// Assigns each element from a Publisher to properties of the provided objects
    ///
    /// - Parameters:
    ///   - keyPath1: The key path of the first property to assign.
    ///   - object1: The first object on which to assign the value.
    ///   - keyPath2: The key path of the second property to assign.
    ///   - object2: The second object on which to assign the value.
    ///   - keyPath3: The key path of the third property to assign.
    ///   - object3: The third object on which to assign the value.
    ///   - ownership: The retainment / ownership strategy for the object, defaults to `strong`.
    ///
    /// - Returns: A cancellable instance; used when you end assignment of the received value.
    ///            Deallocation of the result will tear down the subscription stream.
    func assign<Root1: AnyObject, Root2: AnyObject, Root3: AnyObject>(
        to keyPath1: ReferenceWritableKeyPath<Root1, Output>, on object1: Root1,
        and keyPath2: ReferenceWritableKeyPath<Root2, Output>, on object2: Root2,
        and keyPath3: ReferenceWritableKeyPath<Root3, Output>, on object3: Root3,
        ownership: ObjectOwnership = .strong
    ) -> AnyCancellable {
        switch ownership {
        case .strong:
            return assign(to: keyPath1, on: object1,
                          and: keyPath2, on: object2,
                          and: keyPath3, on: object3)
        case .weak:
            return sink { [weak object1, weak object2, weak object3] value in
                object1?[keyPath: keyPath1] = value
                object2?[keyPath: keyPath2] = value
                object3?[keyPath: keyPath3] = value
            }
        case .unowned:
            return sink { [unowned object1, unowned object2, unowned object3] value in
                object1[keyPath: keyPath1] = value
                object2[keyPath: keyPath2] = value
                object3[keyPath: keyPath3] = value
            }
        }
    }
}


@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: Hashable {
    /// De-duplicates _all_ published value events, as opposed
    /// to pairwise with `Publisher.removeDuplicates`.
    ///
    /// - note: It’s important to note that this operator stores all emitted values
    ///         in an in-memory `Set`. So, use this operator with caution, when handling publishers
    ///         that emit a large number of unique value events.
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream.
    func removeAllDuplicates() -> Publishers.Filter<Self> {
        var seen = Set<Output>()
        return filter { incoming in seen.insert(incoming).inserted }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: Equatable {
    /// `Publisher.removeAllDuplicates` de-duplicates _all_ published `Hashable`-conforming value events, as opposed to pairwise with `Publisher.removeDuplicates`.
    ///
    /// - note: It’s important to note that this operator stores all emitted values in an in-memory `Array`. So, use
    ///         this operator with caution, when handling publishers that emit a large number of unique value events.
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream.
    func removeAllDuplicates() -> Publishers.Filter<Self> {
        removeAllDuplicates(by: ==)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher {
    /// De-duplicates _all_ published value events, along the provided `by` comparator, as opposed to pairwise with `Publisher.removeDuplicates(by:)`.
    ///
    /// - parameter by: A comparator to use when determining uniqueness. `Publisher.removeAllDuplicates` will iterate
    ///                 over all seen values applying each known unique value as the first argument to the comparator and the
    ///                 incoming value event as the second, i.e. `by(see, next) -> Bool`. If this comparator is `true` for any
    ///                 seen value, the next incoming value isn’t emitted downstream.
    ///
    /// - note: It’s important to note that this operator stores all emitted values
    ///         in an in-memory `Array`. So, use this operator with caution, when handling publishers
    ///         that emit a large number of unique value events (as per `by`).
    ///
    /// - returns: A publisher that consumes duplicate values across all previous emissions from upstream
    ///            (signaled with `by`).
    func removeAllDuplicates(by comparator: @escaping (Output, Output) -> Bool) -> Publishers.Filter<Self> {
        var seen = [Output]()
        return filter { incoming in
            if seen.contains(where: { comparator($0, incoming) }) {
                return false
            } else {
                seen.append(incoming)
                return true
            }
        }
    }
}
