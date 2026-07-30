//  BlocObserver.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation

/// Protocol defining the methods that can be overridden to respond to Bloc lifecycle events.
public protocol BlocObserver: AnyObject, Sendable {
    /// Called when a Bloc or Cubit is created.
    /// - Parameter bloc: The bloc that was created.
    func didCreate<Bloc: BlocBase>(_ bloc: Bloc)

    /// Called when a Bloc or Cubit changes state.
    /// - Parameter bloc: The bloc that changed state.
    /// - Parameter previousState: The previous state before the change.
    func didChange<Bloc: BlocBase>(_ bloc: Bloc, previousState: Bloc.State)

    /// Called when a Bloc or Cubit is closed.
    /// - Parameter bloc: The bloc that was closed.
    func didClose<Bloc: BlocBase>(_ bloc: Bloc)
}

/// A default implementation of BlocObserver that does nothing.
open class BlocObserverBase: BlocObserver, @unchecked Sendable {
    public init() { }

    open func didCreate<Bloc: BlocBase>(_ bloc: Bloc) { }

    open func didChange<Bloc: BlocBase>(_ bloc: Bloc, previousState: Bloc.State) { }

    open func didClose<Bloc: BlocBase>(_ bloc: Bloc) { }
}

/// A singleton instance of BlocObserver that can be customized.
public final class BlocObserverImpl: BlocObserverBase, @unchecked Sendable {
    /// The shared instance of BlocObserver.
    public static let shared: BlocObserver = BlocObserverBase()
}