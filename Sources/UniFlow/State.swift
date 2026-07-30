//  State.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import Foundation

/// Protocol that all states must conform to
public protocol StateProtocol: Sendable { }

/// Empty state implementation that conforms to StateProtocol
public struct EmptyState: StateProtocol { }