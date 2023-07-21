import XCTest
@testable import Queryable

/// A helper type that exposes control over Queryable queries.
@MainActor class QueryableObserver<Input, Result> {
    private var queryable: Queryable<Input, Result>
    private var onReceiveQuery: (_ queryId: String, _ input: Input, _ resolver: QueryResolver<Result>) -> Void

    nonisolated private let observer: Task<Void, Never>

    /// A helper type that exposes control over Queryable queries.
    init(
        queryable: Queryable<Input, Result>,
        onReceiveQuery: @escaping (_ queryId: String, _ input: Input, _ resolver: QueryResolver<Result>) -> Void
    ) {
        self.queryable = queryable
        self.onReceiveQuery = onReceiveQuery

        // Setup Listener
        observer = Task {
            for await container in queryable.$itemContainer.values {
                if Task.isCancelled { return }
                if let container {
                    onReceiveQuery(container.id, container.item, container.resolver)
                }
            }
        }
    }

    deinit {
        observer.cancel()
    }

    init(
        queryable: Queryable<Input, Result>,
        onReceiveQuery: @escaping (_ queryId: String, _ resolver: QueryResolver<Result>) -> Void
    ) where Input == Void {
        self.queryable = queryable
        self.onReceiveQuery = { queryId, _, resolver in
            onReceiveQuery(queryId, resolver)
        }

        // Setup Listener
        observer = Task {
            for await container in queryable.$itemContainer.values {
                if Task.isCancelled { return }
                if let container {
                    onReceiveQuery(container.id, container.resolver)
                }
            }
        }
    }

    func finish() {
        observer.cancel()
    }
}
