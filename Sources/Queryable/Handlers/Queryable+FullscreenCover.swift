import SwiftUI

private struct FullScreenCoverModifier<Item, Result, QueryContent: View>: ViewModifier {
    @ObservedObject private var queryable: Queryable<Item, Result>
    private var onDismiss: (() -> Void)?
    private var queryContent: (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent

    public init(
        controlledBy queryable: Queryable<Item, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder queryContent: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent
    ) {
        self.queryable = queryable
        self.onDismiss = onDismiss
        self.queryContent = queryContent
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $queryable.itemContainer, onDismiss: onDismiss) { initialItemContainer in
                StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                    queryContent(itemContainer.item, itemContainer.resolver)
                        .onDisappear {
                            queryable.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                        }
                }
            }
    }
}

public extension View {

    @MainActor
    func queryableFullScreenCover<Item, Result, Content: View>(
        controlledBy queryable: Queryable<Item, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryable, onDismiss: onDismiss, queryContent: content))
    }

    @MainActor
    func queryableFullScreenCover<Result, Content: View>(
        controlledBy queryable: Queryable<Void, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryable, onDismiss: onDismiss) { _, query in
            content(query)
        })
    }
}
