# Migrations

## From 1.x.x to 2.x.x

### Replace All @Queryable Property Wrapper Instances

The `@Queryable` property wrapper has been replaced by a `Queryable` class conforming to `ObservableObject` that you can define anywhere, *inside* as well as *outside* the SwiftUI environment (e.g. in a view model or some other class a view has a access to).

In all your views, replace the following line:

```swift
@Queryable<Input, Result> var myQueryable
```

with this:

```swift
@StateObject var myQueryable = Queryable<Input, Result>
```

The `@StateObject` is only there to let SwiftUI handle the lifecycle of the object, it serves no other purpose.

If you pass a reference of a Queryable down the view hierarchy, replace this:

```swift
var myQueryable: Queryable<Input, Result>.Trigger
```

with this:

```swift
var myQueryable Queryable<Input, Result>
```

All the calls to the `.queryable[...]` view modifiers will still work as before, no changes are needed. 

### Replace Logger Configuration

The logger configuration call has moved outside the generic class. Replace the following line:

```swift
Queryable<Void, Void>.configureLog()
```

with this:

```swift
QueryableLogger.configure()
```
