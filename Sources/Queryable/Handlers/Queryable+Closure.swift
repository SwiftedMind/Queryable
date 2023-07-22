//
//  Copyright © 2023 Dennis Müller and all collaborators
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

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
