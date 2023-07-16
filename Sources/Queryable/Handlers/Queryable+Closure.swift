import SwiftUI

/// Helper type allowing for `nil` checks in SwiftUI without losing the checked item.
///
/// This allows to support item types that are not `Equatable`.
private struct NilEquatableWrapper<WrappedValue>: Equatable {
    let wrappedValue: WrappedValue?

    init(_ wrappedValue: WrappedValue?) {
        self.wrappedValue = wrappedValue
    }

    static func ==(lhs: NilEquatableWrapper<WrappedValue>, rhs: NilEquatableWrapper<WrappedValue>) -> Bool {
        if lhs.wrappedValue == nil {
            return rhs.wrappedValue == nil
        } else {
            return rhs.wrappedValue != nil
        }
    }
}

private struct CustomActionModifier<Item, Result>: ViewModifier {
    @ObservedObject var queryableState: QueryableState<Item, Result>
    var action: (_ item: Item, _ query: QueryResolver<Result>) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: NilEquatableWrapper(queryableState.itemContainer)) { wrapper in
                if let itemContainer = wrapper.wrappedValue {
                    action(itemContainer.item, itemContainer.resolver)
                }
            }
    }
}

public extension View {
    @MainActor func queryableClosure<Item, Result>(
        controlledBy queryable: Trigger<Item, Result>,
        block: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryableState: queryable.queryableState, action: block))
    }

    @MainActor func queryableClosure<Result>(
        controlledBy queryable: Trigger<Void, Result>,
        block: @escaping (_ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryableState: queryable.queryableState) { _, query in
            block(query)
        })
    }

    @MainActor func queryableClosure<Item, Result>(
        controlledBy queryableState: QueryableState<Item, Result>,
        block: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryableState: queryableState, action: block))
    }

    @MainActor func queryableClosure<Result>(
        controlledBy queryableState: QueryableState<Void, Result>,
        block: @escaping (_ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryableState: queryableState) { _, query in
            block(query)
        })
    }
}
