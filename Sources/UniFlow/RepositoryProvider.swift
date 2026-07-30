//  RepositoryProvider.swift
//  UniFlow
//
//  Created by Claude on 2024-01-01
//

import SwiftUI

/// A SwiftUI View that provides a repository object to its subtree via `environmentObject`.
///
/// Usage:
/// ```
/// RepositoryProvider(
///     UserRepository()
/// ) {
///     ProfileView()
/// }
/// ```
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct RepositoryProvider<R: ObservableObject, Content: View>: View {
    @StateObject private var repository: R
    private let content: () -> Content

    /// Creates a RepositoryProvider that creates and holds the repository.
    /// - Parameters:
    ///   - repository: A closure that creates the repository.
    ///   - content: The content to wrap with the repository provider.
    public init(_ repository: @autoclosure @escaping () -> R, @ViewBuilder content: @escaping () -> Content) {
        self._repository = StateObject(wrappedValue: repository())
        self.content = content
    }

    public var body: some View {
        content()
            .environmentObject(repository)
    }
}