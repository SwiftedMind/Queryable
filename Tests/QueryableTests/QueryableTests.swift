import XCTest
@testable import Queryable

@MainActor
final class QueryableTests: XCTestCase {

    private let firstQueryId: String = "firstQueryId"
    private let secondQueryId: String = "secondQueryId"

    func testBasic() async throws {
        let queryable = Queryable<Void, Bool>()
        let observer = QueryableObserver(queryable: queryable) { [firstQueryId, secondQueryId] queryId, resolver in
            if queryId == firstQueryId {
                resolver.answer(with: true)
            } else if queryId == secondQueryId {
                resolver.answer(with: false)
            }
        }

        do {
            let trueResult = try await queryable.query(id: firstQueryId)
            XCTAssertTrue(trueResult)

            let falseResult = try await queryable.query(id: secondQueryId)
            XCTAssertFalse(falseResult)
        } catch {
            XCTFail()
        }

        observer.finish()
    }
    
    /// Tests a simple Queryable with a Boolean input value where the observer answers them with the flipped value.
    func testInput() async throws {
        let queryable = Queryable<Bool, Bool>()
        let observer = QueryableObserver(queryable: queryable) { [firstQueryId, secondQueryId] queryId, item, resolver in
            if queryId == firstQueryId {
                resolver.answer(with: !item)
            } else if queryId == secondQueryId {
                resolver.answer(with: !item)
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

        observer.finish()
    }

    func testConflictResolutionCancelNewQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelNewQuery)
        let observer = QueryableObserver(queryable: queryable) { [firstQueryId, secondQueryId] queryId, resolver in
            if queryId == firstQueryId {
                Task {
                    do {
                        // Start new query that should fail
                        _ = try await queryable.query(id: secondQueryId)
                        XCTFail()
                    } catch is QueryCancellationError {
                        // Then answer this query to end the test
                        resolver.answer()
                    } catch {
                        XCTFail()
                    }
                }
            }
        }

        do {
            try await queryable.query(id: firstQueryId)
        } catch {
            XCTFail()
        }

        observer.finish()
    }

    func testConflictResolutionCancelPreviousQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelPreviousQuery)
        let observer = QueryableObserver(queryable: queryable) { [firstQueryId, secondQueryId] queryId, resolver in
            if queryId == firstQueryId {
                Task {
                    do {
                        // Start new query that should cancel the first one
                        _ = try await queryable.query(id: secondQueryId)
                        resolver.answer()
                    } catch {
                        XCTFail()
                    }
                }
            }
        }

        do {
            try await queryable.query(id: firstQueryId)
            XCTFail()
        } catch {}

        observer.finish()
    }
}
