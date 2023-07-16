import SwiftUI

private struct OverlayModifier<Item, Result, QueryContent: View>: ViewModifier {
    @ObservedObject private var queryableState: QueryableState<Item, Result>
    private var animation: Animation? = nil
    private var alignment: Alignment = .center
    private var queryContent: (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent

    public init(
        controlledBy queryableState: QueryableState<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder queryContent: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent
    ) {
        self.queryableState = queryableState
        self.animation = animation
        self.alignment = alignment
        self.queryContent = queryContent
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                ZStack {
                    if let initialItemContainer = queryableState.itemContainer {
                        StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                            queryContent(itemContainer.item, initialItemContainer.resolver)
                                .onDisappear {
                                    queryableState.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                                }
                        }
                    }
                }
                .animation(animation, value: queryableState.itemContainer == nil)
            }
    }
}

public extension View {

    /// Shows an overlay controlled by a ``Queryable/Queryable``.
    @MainActor
    func queryableOverlay<Item, Result, Content: View>(
        controlledBy queryable: Trigger<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryable.queryableState, animation: animation, alignment: alignment, queryContent: content))
    }

    /// Shows an overlay controlled by a ``Queryable/Queryable`` whose `Input` is of type `Void`.
    ///
    /// This is a convenience overload to remove the unnecessary `item` argument in the `content` ViewBuilder.
    @MainActor
    func queryableOverlay<Result, Content: View>(
        controlledBy queryable: Trigger<Void, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryable.queryableState, animation: animation, alignment: alignment) { _, query in
            content(query)
        })
    }

    @MainActor
    func queryableOverlay<Item, Result, Content: View>(
        controlledBy queryableState: QueryableState<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryableState, animation: animation, alignment: alignment, queryContent: content))
    }

    @MainActor
    func queryableOverlay<Result, Content: View>(
        controlledBy queryableState: QueryableState<Void, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryableState, animation: animation, alignment: alignment) { _, query in
            content(query)
        })
    }
}
