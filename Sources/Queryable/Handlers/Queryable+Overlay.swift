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
