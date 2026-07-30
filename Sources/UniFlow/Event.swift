//  Event.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation

/// A marker protocol for the events a `Bloc` processes.
///
/// Conform your own event type — typically an `enum` with one case per user
/// action or system occurrence — to `Event`, then declare your `Bloc` subclass
/// generic over it:
///
/// ```swift
/// enum CounterEvent: Event {
///     case increment
///     case decrement
/// }
/// ```
///
/// `Cubit` doesn't use events at all; skip this protocol if you're using `Cubit`.
public protocol Event: Sendable { }