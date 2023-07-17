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
    @ObservedObject var queryable: Queryable<Item, Result>
    var action: (_ item: Item, _ query: QueryResolver<Result>) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: NilEquatableWrapper(queryable.itemContainer)) { wrapper in
                if let itemContainer = wrapper.wrappedValue {
                    action(itemContainer.item, itemContainer.resolver)
                }
            }
    }
}

public extension View {

    @MainActor func queryableClosure<Item, Result>(
        controlledBy queryable: Queryable<Item, Result>,
        block: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryable: queryable, action: block))
    }

    @MainActor func queryableClosure<Result>(
        controlledBy queryable: Queryable<Void, Result>,
        block: @escaping (_ query: QueryResolver<Result>) -> Void
    ) -> some View {
        modifier(CustomActionModifier(queryable: queryable) { _, query in
            block(query)
        })
    }
}
