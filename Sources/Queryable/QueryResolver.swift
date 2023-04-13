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
