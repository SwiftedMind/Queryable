import SwiftUI

public extension View {

    /// Presents a sheet controlled by a ``Puddles/Queryable``.
    @MainActor
    func queryableSheet<Item, Result, Content: View>(
        controlledBy queryable: Queryable<Item, Result>.Trigger,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Content
    ) -> some View {
        sheet(item: queryable.itemContainer, onDismiss: onDismiss) { initialItemContainer in
            StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                content(itemContainer.item, itemContainer.resolver)
                    .onDisappear {
                        queryable.manager.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                    }
            }
        }
    }

    /// Presents a sheet controlled by a ``Puddles/Queryable`` whose `Input` is of type `Void`.
    ///
    /// This is a convenience overload to remove the unnecessary `item` argument in the `content` ViewBuilder.
    @MainActor
    func queryableSheet<Result, Content: View>(
        controlledBy queryable: Queryable<Void, Result>.Trigger,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ query: QueryResolver<Result>) -> Content
    ) -> some View {
        sheet(item: queryable.itemContainer, onDismiss: onDismiss) { initialItemContainer in
            StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                content(itemContainer.resolver)
                    .onDisappear {
                        queryable.manager.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                    }
            }
        }
    }
}
