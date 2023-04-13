//
//  Copyright © 2023 Dennis Müller and all collaborators
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Combine
import SwiftUI

/// A property wrapper type that can trigger a view presentation from within an `async` function and `await` its completion and potential result value.
///
/// An example use case would be a boolean coming from a confirmation dialog view. First, create a property of the desired data type:
///
/// ```swift
/// @Queryable<String, Bool> var deletionConfirmation
/// ```
///
/// Then, use one of the `queryable` prefixed presentation modifiers to show the deletion confirmation. For instance, here we use an alert:
///
/// ```swift
/// someView
///   .queryableAlert(
///     controlledBy: deletionConfirmation,
///     title: "Do you want to delete this?") { itemName, query in
///       Button("Cancel", role: .cancel) {
///         query.answer(with: false)
///       }
///       Button("OK") {
///         query.answer(with: true)
///       }
///     } message: { itemName in
///       Text("This cannot be reversed!")
///     }
/// ```
///
/// To actually present the alert and await the boolean result, call ``Queryable/Queryable/Trigger/query(with:)`` on the ``Queryable/Queryable`` property.
/// This will activate the alert presentation which can then resolve the query in its completion handler.
///
/// ```swift
/// do {
///   let item = // ...
///   let shouldDelete = try await deletionConfirmation.query(with: item.name)
/// } catch {}
/// ```
///
/// When the Task that calls ``Queryable/Queryable/Trigger/query(with:)`` is cancelled, the suspended query will also cancel and deactivate (i.e. close) the wrapped navigation presentation.
/// In that case, a ``Queryable/QueryCancellationError`` error is thrown.
@propertyWrapper
public struct Queryable<Input, Result>: DynamicProperty where Input: Sendable, Result: Sendable {

    public var wrappedValue: Trigger {
        .init(
            itemContainer: $manager.itemContainer,
            manager: manager
        )
    }

    @StateObject private var manager: QueryableManager<Input, Result>

    public init(queryConflictPolicy: QueryConflictPolicy = .cancelPreviousQuery) {
        _manager = .init(wrappedValue: .init(queryConflictPolicy: queryConflictPolicy))
    }

    /// A type that is capable of triggering and cancelling a query.
    public struct Trigger {

        /// A binding to the `item` state inside the `@Queryable` property wrapper.
        ///
        /// This is used internally inside ``Queryable/Queryable/Wrapper/query()``.
        var itemContainer: Binding<QueryableManager<Input, Result>.ItemContainer?>

        /// A property that stores the `Result` type to be used in logging messages.
        var expectedType: Result.Type {
            Result.self
        }

        var manager: QueryableManager<Input, Result>

        /// A representation of the `Queryable` property wrapper type. This can be passed to `queryable` prefixed presentation modifiers, like `queryableSheet`.
        init(
            itemContainer: Binding<QueryableManager<Input, Result>.ItemContainer?>,
            manager: QueryableManager<Input, Result>
        ) {
            self.itemContainer = itemContainer
            self.manager = manager
        }

        /// Requests the collection of data by starting a query on the `Result` type, providing an input value.
        ///
        /// This method will suspend for as long as the query is unanswered and not cancelled. When the parent Task is cancelled, this method will immediately cancel the query and throw a ``Queryable/QueryCancellationError`` error.
        ///
        /// Creating multiple queries at the same time will cause a query conflict which is resolved using the ``Queryable/QueryConflictPolicy`` defined in the initializer of ``Queryable/Queryable``. The default policy is ``Queryable/QueryConflictPolicy/cancelPreviousQuery``.
        /// - Returns: The result of the query.
        @MainActor
        public func query(with item: Input) async throws -> Result {
            let id = UUID()
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    manager.storeContinuation(continuation, withId: id, item: item)
                }
            } onCancel: {
                Task {
                    await manager.autoCancelContinuation(id: id, reason: .taskCancelled)
                }
            }
        }

        @MainActor
        public func query() async throws -> Result where Input == Void {
            try await query(with: ())
        }

        /// Cancels any ongoing queries.
        @MainActor
        public func cancel() {
            manager.itemContainer?.resolver.answer(throwing: QueryCancellationError())
        }

        /// A flag indicating if a query is active.
        @MainActor
        public var isQuerying: Bool {
            itemContainer.wrappedValue != nil
        }
    }
}
