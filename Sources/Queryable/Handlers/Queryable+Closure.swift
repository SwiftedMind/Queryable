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

public extension View {
    func queryableClosure<Item, Result>(
        controlledBy queryable: Queryable<Item, Result>.Trigger,
        block: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> Void
    ) -> some View {
        onChange(of: NilEquatableWrapper(queryable.itemContainer.wrappedValue)) { wrapper in
            if let itemContainer = wrapper.wrappedValue {
                block(itemContainer.item, itemContainer.resolver)
            }
        }
    }

    func queryableClosure<Result>(
        controlledBy queryable: Queryable<Void, Result>.Trigger,
        block: @escaping (_ query: QueryResolver<Result>) -> Void
    ) -> some View {
        onChange(of: NilEquatableWrapper(queryable.itemContainer.wrappedValue)) { wrapper in
            if let itemContainer = wrapper.wrappedValue {
                block(itemContainer.resolver)
            }
        }
    }
}
