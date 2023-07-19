import XCTest
@testable import Queryable

@MainActor
class QueryableObserver<Input, Result> {
    private var queryable: Queryable<Input, Result>
    private var onReceiveQuery: (_ queryId: String, _ input: Input, _ resolver: QueryResolver<Result>) -> Void

    init(
        queryable: Queryable<Input, Result>,
        onReceiveQuery: @escaping (_ queryId: String, _ input: Input, _ resolver: QueryResolver<Result>) -> Void
    ) {
        self.queryable = queryable
        self.onReceiveQuery = onReceiveQuery

        // Setup Listener
        Task {
            for await container in queryable.$itemContainer.values {
                if let container {
                    onReceiveQuery(container.id, container.item, container.resolver)
                }
            }
        }
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
        Task {
            for await container in queryable.$itemContainer.values {
                if let container {
                    onReceiveQuery(container.id, container.resolver)
                }
            }
        }
    }
}
