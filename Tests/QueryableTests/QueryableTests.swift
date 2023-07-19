import XCTest
@testable import Queryable

@MainActor
final class QueryableTests: XCTestCase {

    func testBasic() async throws {
        let queryable = Queryable<Void, Bool>()
        _ = QueryableObserver(queryable: queryable) { queryId, resolver in
            if queryId == "0" {
                resolver.answer(with: true)
            } else if queryId == "1" {
                resolver.answer(with: false)
            }
        }

        do {
            let trueResult = try await queryable.query(id: "0")
            XCTAssertTrue(trueResult)

            let falseResult = try await queryable.query(id: "1")
            XCTAssertFalse(falseResult)
        } catch {
            XCTFail()
        }
    }
    
    /// Tests a simple Queryable with a Boolean input value where the observer answers them with the flipped value.
    func testInput() async throws {
        let queryable = Queryable<Bool, Bool>()
        _ = QueryableObserver(queryable: queryable) { queryId, item, resolver in
            if queryId == "0" {
                resolver.answer(with: !item)
            } else if queryId == "1" {
                resolver.answer(with: !item)
            }
        }

        do {
            let trueResult = try await queryable.query(with: true, id: "0")
            XCTAssertFalse(trueResult)

            let falseResult = try await queryable.query(with: false, id: "1")
            XCTAssertTrue(falseResult)
        } catch {
            XCTFail()
        }
    }

    func testConflictResolutionCancelNewQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelNewQuery)
        _ = QueryableObserver(queryable: queryable) { queryId, resolver in
            if queryId == "0" {
                Task {
                    do {
                        // Start new query that should fail
                        _ = try await queryable.query(id: "1")
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
            try await queryable.query(id: "0")
        } catch {
            XCTFail()
        }
    }

    func testConflictResolutionCancelPreviousQuery() async throws {
        let queryable = Queryable<Void, Void>(queryConflictPolicy: .cancelPreviousQuery)
        _ = QueryableObserver(queryable: queryable) { queryId, resolver in
            if queryId == "0" {
                Task {
                    do {
                        // Start new query that should cancel the first one
                        _ = try await queryable.query(id: "1")
                        resolver.answer()
                    } catch {
                        XCTFail()
                    }
                }
            }
        }

        do {
            try await queryable.query(id: "0")
            XCTFail()
        } catch {}
    }
}
