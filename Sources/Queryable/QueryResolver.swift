import Foundation

/// A type that lets you answer a query made by a call to ``Puddles/Queryable/Trigger/query()``.
@MainActor
public struct QueryResolver<Result>: Sendable {

    private let answerHandler: (Result) -> Void
    private let cancelHandler: (Error) -> Void

    /// A type that lets you answer a query made by a call to ``Puddles/Queryable/Trigger/query()``.
    init(
        answerHandler: @escaping (Result) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        self.answerHandler = answerHandler
        self.cancelHandler = errorHandler
    }

    /// Answers the query with a result.
    /// - Parameter result: The result of the query.
    public func answer(with result: Result) {
        answerHandler(result)
    }

    /// Answers the query with an optional result. If it is `nil`,  this will call ``Puddles/QueryResolver/cancelQuery()``.
    /// - Parameter result: The result of the query, as an optional.
    public func answer(withOptional optionalResult: Result?) {
        if let optionalResult {
            answerHandler(optionalResult)
        } else {
            cancelQuery()
        }
    }

    /// Answers the query.
    public func answer() where Result == Void {
        answerHandler(())
    }

    /// Answers the query by throwing an error.
    /// - Parameter error: The error to throw.
    public func answer(throwing error: Error) {
        cancelHandler(error)
    }

    /// Cancels the query by throwing a ``Puddles/QueryCancellationError`` error.
    public func cancelQuery() {
        cancelHandler(QueryCancellationError())
    }
}
