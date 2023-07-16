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

import Foundation
import Combine

/// An internal manager that handles the logic of presenting views and storing continuations.
@MainActor
public final class QueryableState<Input, Result>: ObservableObject where Input: Sendable, Result: Sendable {
    private let queryConflictPolicy: QueryConflictPolicy
    var storedContinuationState: ContinuationState?

    /// Optional item storing the input value for a query and is used to indicate if the query has started, which usually coincides with a presentation being shown.
    @Published var itemContainer: ItemContainer?

    public init(queryConflictPolicy: QueryConflictPolicy = .cancelNewQuery) {
        self.queryConflictPolicy = queryConflictPolicy
    }

    // MARK: - Public Interface

    /// Requests the collection of data by starting a query on the `Result` type, providing an input value.
    ///
    /// This method will suspend for as long as the query is unanswered and not cancelled. When the parent Task is cancelled, this method will immediately cancel the query and throw a ``Queryable/QueryCancellationError`` error.
    ///
    /// Creating multiple queries at the same time will cause a query conflict which is resolved using the ``Queryable/QueryConflictPolicy`` defined in the initializer of ``Queryable/Queryable``. The default policy is ``Queryable/QueryConflictPolicy/cancelPreviousQuery``.
    /// - Returns: The result of the query.
    public func query(with item: Input) async throws -> Result {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                storeContinuation(continuation, withId: id, item: item)
            }
        } onCancel: {
            Task {
                await autoCancelContinuation(id: id, reason: .taskCancelled)
            }
        }
    }

    /// Requests the collection of data by starting a query on the `Result` type, providing an input value.
    ///
    /// This method will suspend for as long as the query is unanswered and not cancelled. When the parent Task is cancelled, this method will immediately cancel the query and throw a ``Queryable/QueryCancellationError`` error.
    ///
    /// Creating multiple queries at the same time will cause a query conflict which is resolved using the ``Queryable/QueryConflictPolicy`` defined in the initializer of ``Queryable/Queryable``. The default policy is ``Queryable/QueryConflictPolicy/cancelPreviousQuery``.
    /// - Returns: The result of the query.
    public func query() async throws -> Result where Input == Void {
        try await query(with: ())
    }

    /// Cancels any ongoing queries.
    public func cancel() {
        itemContainer?.resolver.answer(throwing: QueryCancellationError())
    }

    /// A flag indicating if a query is active.
    public var isQuerying: Bool {
        itemContainer != nil
    }

    // MARK: - Internal Interface

    func storeContinuation(
        _ newContinuation: CheckedContinuation<Result, Swift.Error>,
        withId id: UUID,
        item: Input
    ) {
        if let storedContinuationState {
            switch queryConflictPolicy {
            case .cancelPreviousQuery:
                logger.warning("Cancelling previous query of »\(Result.self, privacy: .public)« to allow new query.")
                storedContinuationState.continuation.resume(throwing: QueryCancellationError())
                self.storedContinuationState = nil
                self.itemContainer = nil
            case .cancelNewQuery:
                logger.warning("Cancelling new query of »\(Result.self, privacy: .public)« because another query is ongoing.")
                newContinuation.resume(throwing: QueryCancellationError())
                return
            }
        }

        let resolver = QueryResolver<Result> { result in
            self.resumeContinuation(returning: result, queryId: id)
        } errorHandler: {  error in
            self.resumeContinuation(throwing: error, queryId: id)
        }

        storedContinuationState = .init(queryId: id, continuation: newContinuation)
        itemContainer = .init(queryId: id, item: item, resolver: resolver)
    }

    func autoCancelContinuation(id: UUID, reason: AutoCancelReason) {
        // If the user cancels a query programmatically and immediately starts the next one, we need to prevent the `QueryInternalError.queryAutoCancel` from the `onDisappear` handler of the canceled query to cancel the new query. That's why the presentations store an id
        if storedContinuationState?.queryId == id {
            switch reason {
            case .presentationEnded:
                logger.notice("Cancelling query of »\(Result.self, privacy: .public)« because presentation has terminated.")
            case .taskCancelled:
                logger.notice("Cancelling query of »\(Result.self, privacy: .public)« because the task was cancelled.")
            }

            storedContinuationState?.continuation.resume(throwing: QueryCancellationError())
            storedContinuationState = nil
            itemContainer = nil
        }
    }

    // MARK: - Private Interface

    private func resumeContinuation(returning result: Result, queryId: UUID) {
        guard itemContainer?.id == queryId else { return }
        storedContinuationState?.continuation.resume(returning: result)
        storedContinuationState = nil
        itemContainer = nil
    }

    private func resumeContinuation(throwing error: Error, queryId: UUID) {
        guard itemContainer?.id == queryId else { return }
        storedContinuationState?.continuation.resume(throwing: error)
        storedContinuationState = nil
        itemContainer = nil
    }
}

// MARK: - Auxiliary Types

extension QueryableState {
    struct ItemContainer: Sendable, Identifiable {
        var id: UUID { queryId }
        let queryId: UUID
        var item: Input
        var resolver: QueryResolver<Result>
    }

    struct ContinuationState: Sendable {
        let queryId: UUID
        var continuation: CheckedContinuation<Result, Swift.Error>
    }

    enum AutoCancelReason {
        case presentationEnded
        case taskCancelled
    }
}
