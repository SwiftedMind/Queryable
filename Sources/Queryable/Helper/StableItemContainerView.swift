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

/// A SwiftUI view that takes an item container provided at initialization and maintains its
/// initial state for the lifetime of the view. This view can be used to ensure a particular
/// state remains constant while working with SwiftUI views, which might rebuild or reevaluate
/// their content at different times.
struct StableItemContainerView<Content: View, Input, Result>: View where Input: Sendable, Result: Sendable {

    /// A private state property to store the initial item container.
    @State private var itemContainer: Queryable<Input, Result>.ItemContainer

    /// A closure that defines the content of the view, accepting the item container as its argument.
    private let content: (_ itemContainer: Queryable<Input, Result>.ItemContainer) -> Content

    /// Initializes a new `StableItemContainerView` with the given item container and a closure
    /// that defines the content of the view.
    ///
    /// - Parameters:
    ///   - itemContainer: The item container that will be provided to the content of the view
    ///                    and maintained for the view's lifetime.
    ///   - content: A closure that defines the content of the view, which accepts the item container
    ///              as its argument.
    init(
        itemContainer: Queryable<Input, Result>.ItemContainer,
        @ViewBuilder content: @escaping (_ itemContainer: Queryable<Input, Result>.ItemContainer) -> Content
    ) {
        _itemContainer = .init(initialValue: itemContainer)
        self.content = content
    }

    var body: some View {
        content(itemContainer)
    }
}
