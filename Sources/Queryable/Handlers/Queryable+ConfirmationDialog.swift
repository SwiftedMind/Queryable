import SwiftUI

private struct QueryableConfirmationDialogModifier<Item, Result, Actions: View, Message: View>: ViewModifier {

    @State private var ids: [UUID] = []

    var queryable: Queryable<Item, Result>.Trigger
    var title: String
    @ViewBuilder var actions: (_ item: Item, _ query: QueryResolver<Result>) -> Actions
    @ViewBuilder var message: (_ item: Item) -> Message

    func body(content: Content) -> some View {
        content
            .background {
                if let initialItemContainer = queryable.itemContainer.wrappedValue {
                    ZStack {
                        StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                            Color.clear
                                .confirmationDialog(
                                    title,
                                    isPresented: .constant(true)
                                ) {
                                    actions(itemContainer.item, itemContainer.resolver)
                                } message: {
                                    message(itemContainer.item)
                                        .onDisappear {
                                            if let id = ids.first {
                                                queryable.manager.autoCancelContinuation(id: id, reason: .presentationEnded)
                                                ids.removeFirst()
                                            }
                                        }
                                }
                        }
                        .onAppear { ids.append(initialItemContainer.id) }
                    }
                    .id(initialItemContainer.id)
                }
            }
    }
}

public extension View {

    /// Shows a confirmation dialog controlled by a ``Puddles/Queryable``.
    @MainActor
    func queryableConfirmationDialog<Item, Result, Actions: View, Message: View>(
        controlledBy queryable: Queryable<Item, Result>.Trigger,
        title: String,
        @ViewBuilder actions: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping (_ item: Item) -> Message
    ) -> some View {
        modifier(QueryableConfirmationDialogModifier(queryable: queryable, title: title, actions: actions, message: message))
    }

    @MainActor
    func queryableConfirmationDialog<Result, Actions: View, Message: View>(
        controlledBy queryable: Queryable<Void, Result>.Trigger,
        title: String,
        @ViewBuilder actions: @escaping (_ query: QueryResolver<Result>) -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        modifier(
            QueryableConfirmationDialogModifier(queryable: queryable, title: title) { _, query in
                actions(query)
            } message: { _ in
                message()
            }
        )
    }
}
