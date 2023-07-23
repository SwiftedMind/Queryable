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
final class BasicTests: XCTestCase {

    private let firstQueryId: String = "firstQueryId"
    private let secondQueryId: String = "secondQueryId"

    override func setUp() async throws {
        executionTimeAllowance = 5
        continueAfterFailure = false
    }

    func testBasic() async throws {
        let queryable = Queryable<Void, Bool>()

        let task = Task {
            for await observation in queryable.queryObservation {
                observation.resolver.answer(with: true)
                return
            }
        }

        do {
            let trueResult = try await queryable.query()
            XCTAssertTrue(trueResult)
        } catch {
            XCTFail()
        }

        await task.value
    }

    func testBasicThrowing() async throws {
        let queryable = Queryable<Void, Bool>()

        let task = Task {
            for await observation in queryable.queryObservation {
                observation.resolver.answer(throwing: TestError())
                return
            }
        }

        do {
            _ = try await queryable.query()
            XCTFail()
        } catch {
            XCTAssert(error is TestError, "Unexpected error was thrown")
        }

        await task.value
    }

    func testInput() async throws {
        let queryable = Queryable<Bool, Bool>()

        let task = Task {
            for await observation in queryable.queryObservation {
                observation.resolver.answer(with: !observation.input)
            }
        }

        do {
            let trueResult = try await queryable.query(with: true, id: firstQueryId)
            XCTAssertFalse(trueResult)

            let falseResult = try await queryable.query(with: false, id: secondQueryId)
            XCTAssertTrue(falseResult)
        } catch {
            XCTFail()
        }

        task.cancel()
    }

    func testCancellation() async throws {
        let queryable = Queryable<Void, Void>()

        let task = Task {
            for await _ in queryable.queryObservation {
                queryable.cancel()
                return
            }
        }

        do {
            _ = try await queryable.query()
            XCTFail()
        } catch is QueryCancellationError {
            // Expected
        } catch {
            XCTFail()
        }

        await task.value
    }

    func testTaskCancellation() async throws {
        let queryable = Queryable<Void, Void>()

        let task = Task {
            await withTaskGroup(of: Void.self) { group in

                group.addTask {
                    do {
                        _ = try await queryable.query()
                        XCTFail()
                    } catch is QueryCancellationError {
                        // Expected
                    } catch {
                        XCTFail()
                    }
                }

                group.cancelAll()
            }
        }

        await task.value
    }
}
