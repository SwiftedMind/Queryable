//
//  IfQueryable.swift
//
//
//  Created by Kai Quan Tay on 12/1/24.
//

import SwiftUI

public struct IfQueryable<Item, Result, QueryContent: View>: View {
    @ObservedObject private var queryable: Queryable<Item, Result>
    private var animation: Animation? = nil
    private var alignment: Alignment = .center
    private var queryContent: (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent

    public init(
        _ queryable: Queryable<Item, Result>,
        animation: Animation? = nil,
        alignment: Alignment = .center,
        @ViewBuilder queryContent: @escaping (_ item: Item, _ query: QueryResolver<Result>) -> QueryContent
    ) {
        self.queryable = queryable
        self.animation = animation
        self.alignment = alignment
        self.queryContent = queryContent
    }

    public var body: some View {
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
