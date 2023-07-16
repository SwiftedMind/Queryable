import SwiftUI

private struct FullScreenCoverModifier<Item, Result, QueryContent: View>: ViewModifier {
    @ObservedObject private var queryableState: QueryableState<Item, Result>
    private var onDismiss: (() -> Void)?
    private var queryContent: (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent

    public init(
        controlledBy queryableState: QueryableState<Item, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder queryContent: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent
    ) {
        self.queryableState = queryableState
        self.onDismiss = onDismiss
        self.queryContent = queryContent
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $queryableState.itemContainer, onDismiss: onDismiss) { initialItemContainer in
                StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                    queryContent(itemContainer.item, itemContainer.resolver)
                        .onDisappear {
                            queryableState.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                        }
                }
            }
    }
}

public extension View {

    /// Presents a sheet controlled by a ``Queryable/Queryable``.
    @MainActor
    @available(macOS, unavailable)
    func queryableFullScreenCover<Item, Result, Content: View>(
        controlledBy queryable: Trigger<Item, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryable.queryableState, onDismiss: onDismiss, queryContent: content))
    }

    /// Presents a sheet controlled by a ``Queryable/Queryable`` whose `Input` is of type `Void`.
    ///
    /// This is a convenience overload to remove the unnecessary `item` argument in the `content` ViewBuilder.
    @MainActor
    @available(macOS, unavailable)
    func queryableFullScreenCover<Result, Content: View>(
        controlledBy queryable: Trigger<Void, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryable.queryableState, onDismiss: onDismiss) { _, query in
            content(query)
        })
    }

    @MainActor
    func queryableFullScreenCover<Item, Result, Content: View>(
        controlledBy queryableState: QueryableState<Item, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryableState, onDismiss: onDismiss, queryContent: content))
    }

    @MainActor
    func queryableFullScreenCover<Result, Content: View>(
        controlledBy queryableState: QueryableState<Void, Result>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(controlledBy: queryableState, onDismiss: onDismiss) { _, query in
            content(query)
        })
    }
}
