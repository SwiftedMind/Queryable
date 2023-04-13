import SwiftUI

public extension View {

    /// Shows an overlay controlled by a ``Queryable/Queryable``.
    @MainActor
    func queryableOverlay<Item, Result, Content: View>(
        controlledBy queryable: Queryable<Item, Result>.Trigger,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        overlay(alignment: alignment) {
            ZStack {
                if let initialItemContainer = queryable.itemContainer.wrappedValue {
                    StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                        content(itemContainer.item, initialItemContainer.resolver)
                            .onDisappear {
                                queryable.manager.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                            }
                    }
                }
            }
            .animation(animation, value: queryable.itemContainer.wrappedValue == nil)
        }
    }

    /// Shows an overlay controlled by a ``Queryable/Queryable`` whose `Input` is of type `Void`.
    ///
    /// This is a convenience overload to remove the unnecessary `item` argument in the `content` ViewBuilder.
    @MainActor
    func queryableOverlay<Result, Content: View>(
        controlledBy queryable: Queryable<Void, Result>.Trigger,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        overlay(alignment: alignment) {
            ZStack {
                if let initialItemContainer = queryable.itemContainer.wrappedValue {
                    StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                        content(itemContainer.resolver)
                            .onDisappear {
                                queryable.manager.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                            }
                    }
                }
            }
            .animation(animation, value: queryable.itemContainer.wrappedValue == nil)
        }
    }

    @MainActor
    func queryableToast<Item, Result, Content: View>(
        controlledBy queryable: Queryable<Item, Result>.Trigger,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) {

    }
}
