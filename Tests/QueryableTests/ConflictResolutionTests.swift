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

import XCTest
@testable import Queryable

@MainActor
final class ConflictResolutionTests: XCTestCase {

    private let firstQueryId: String = "firstQueryId"
    private let secondQueryId: String = "secondQueryId"

    override func setUp() async throws {
        executionTimeAllowance = 5
        continueAfterFailure = false
    }


    func testCancelNewQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelNewQuery)

        let task = Task {
            await withTaskGroup(of: Void.self) { [firstQueryId, secondQueryId] group in

                // Observe first query
                group.addTask {
                    for await observation in await queryable.queryObservation where observation.queryId == firstQueryId {
                        do {
                            _ = try await queryable.query(id: secondQueryId)
                            XCTFail()
                            await observation.resolver.answer(throwing: UnexpectedBehavior())
                        } catch is QueryCancellationError {
                            // Expected
                            await observation.resolver.answer()
                        } catch {
                            XCTFail()
                            await observation.resolver.answer(throwing: UnexpectedBehavior())
                        }

                        return
                    }
                }

                // Observe second query
                group.addTask {
                    for await observation in await queryable.queryObservation where observation.queryId == secondQueryId {
                        await observation.resolver.answer()
                        XCTFail()
                        return
                    }
                }

                await group.next()
                group.cancelAll()
            }
        }

        do {
            _ = try await queryable.query(id: firstQueryId)
        } catch is QueryCancellationError {
            XCTFail()
        } catch {
            XCTFail()
        }

        await task.value
    }

    func testPreviousQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelPreviousQuery)

        let task = Task {
            await withTaskGroup(of: Void.self) { [firstQueryId, secondQueryId] group in

                // Observe first query
                group.addTask {
                    for await observation in await queryable.queryObservation where observation.queryId == firstQueryId {
                        do {
                            _ = try await queryable.query(id: secondQueryId)
                        } catch is QueryCancellationError {
                            XCTFail()
                            await observation.resolver.answer(throwing: UnexpectedBehavior())
                        } catch {
                            XCTFail()
                            await observation.resolver.answer(throwing: UnexpectedBehavior())
                        }

                        return
                    }
                }

                // Observe second query
                group.addTask {
                    for await observation in await queryable.queryObservation where observation.queryId == secondQueryId {
                        await observation.resolver.answer()
                        return
                    }
                }

                await group.next()
                group.cancelAll()
            }
        }

        do {
            _ = try await queryable.query(id: firstQueryId)
            XCTFail()
        } catch is QueryCancellationError {
            // Expected
        } catch {
            XCTFail()
        }

        await task.value
    }
}
