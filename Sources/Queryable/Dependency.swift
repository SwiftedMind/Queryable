import SwiftUI
import Combine

@propertyWrapper @MainActor
public struct Dependency<Value, Action>: DynamicProperty {

    private var interface: Interface<Action>

    public var wrappedValue: Value

    public var projectedValue: Interface<Action> {
        interface
    }

    private init(wrappedValue: Value, interface: Interface<Action>) {
        self.wrappedValue = wrappedValue
        self.interface = interface
    }

    public static func resolved<Value, Action>(
        _ value: Value,
        interface: Interface<Action> = .ignore
    ) -> Dependency<Value, Action> {
        .init(wrappedValue: value, interface: interface)
    }

    public static func resolved<Value, Action, Provider: DataProvider<Value, Action>>(
        by provider: Provider
    ) -> Dependency<Value, Action> {
        .init(wrappedValue: provider.value, interface: .consume(provider.handleAction))
    }
}

@MainActor
public protocol DataProvider<Value, Action>: ObservableObject {
    associatedtype Value
    associatedtype Action
    var value: Value { get }
    func handleAction(_ action: Action) -> Void
}
