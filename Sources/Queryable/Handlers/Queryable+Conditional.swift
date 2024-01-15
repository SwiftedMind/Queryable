//
//  IfQueryable.swift
//
//
//  Created by Kai Quan Tay on 12/1/24.
//

import SwiftUI

public struct WithQuery<Item, Result, QueryContent: View>: View {
    @ObservedObject private var queryable: Queryable<Item, Result>
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

    public init(
        _ queryable: Queryable<Void, Result>,
        @ViewBuilder queryContent: @escaping (_ query: QueryResolver<Result>) -> QueryContent
    ) where Item == Void {
        self.queryable = queryable
        self.queryContent = { _, query in queryContent(query) }
    }

    public var body: some View {
        if let initialItemContainer = queryable.itemContainer {
            StableItemContainerView(itemContainer: initialItemContainer) { itemContainer in
                queryContent(itemContainer.item, initialItemContainer.resolver)
                    .onDisappear {
                        queryable.autoCancelContinuation(id: itemContainer.id, reason: .presentationEnded)
                    }
            }
        }
    }
}
