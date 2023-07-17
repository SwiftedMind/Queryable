import SwiftUI

private struct OverlayModifier<Item, Result, QueryContent: View>: ViewModifier {
    @ObservedObject private var queryable: Queryable<Item, Result>
    private var animation: Animation? = nil
    private var alignment: Alignment = .center
    private var queryContent: (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent

    public init(
        controlledBy queryable: Queryable<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder queryContent: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent
    ) {
        self.queryable = queryable
        self.animation = animation
        self.alignment = alignment
        self.queryContent = queryContent
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                ZStack {
                    if let initialItemContainer = queryable.itemContainer {
                        StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                            queryContent(itemContainer.item, initialItemContainer.resolver)
                                .onDisappear {
                                    queryable.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                                }
                        }
                    }
                }
                .animation(animation, value: queryable.itemContainer == nil)
            }
    }
}

public extension View {

    @MainActor
    func queryableOverlay<Item, Result, Content: View>(
        controlledBy queryable: Queryable<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryable, animation: animation, alignment: alignment, queryContent: content))
    }

    @MainActor
    func queryableOverlay<Result, Content: View>(
        controlledBy queryable: Queryable<Void, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        modifier(OverlayModifier(controlledBy: queryable, animation: animation, alignment: alignment) { _, query in
            content(query)
        })
    }
}
