
<p align="center">
  <img width="200" height="200" src="https://user-images.githubusercontent.com/7083109/231827191-7472e663-a8f2-42c6-a7aa-77bb38ae484a.png">
</p>

# Queryable - Asynchronous View Presentations in SwiftUI
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FQueryable%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SwiftedMind/Queryable)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FQueryable%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SwiftedMind/Queryable)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/SwiftedMind/Queryable?label=Latest%20Release)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Queryable)

`Queryable` is a property wrapper that can trigger a view presentation and `await` its completion from a single `async` function call, while fully hiding the state handling of the presented view.

```swift
import SwiftUI
import Queryable

struct ContentView: View {
  @Queryable<Void, Bool> var buttonConfirmation

  var body: some View {
    Button("Commit", action: confirm)
      .queryableAlert(controlledBy: buttonConfirmation, title: "Really?") { item, query in
          Button("Yes") { query.answer(with: true) }
          Button("No") { query.answer(with: false) }
      } message: {_ in}
  }

  @MainActor
  private func confirm() {
    Task {
      do {
        let isConfirmed = try await buttonConfirmation.query()
        // Do something with the result
      } catch {}
    }
  }
}
```

Not only does this free the presented view from any kind of context (it simply provides an answer to the query), but you can also pass `buttonConfirmation` down the view hierarchy so that any child view can conveniently trigger the confirmation without needing to deal with the actually displayed UI. It works with `alerts`, `confirmationDialogs`, `sheets`, `fullScreenCover` and fully custom `overlays`.

- [Installation](#installation)
- **[Get Started](#get-started)**
- [Supported Queryable Modifiers](#supported-queryable-modifiers)
- [License](#license)

## Installation

Queryable supports iOS 15+, macOS 12+, watchOS 8+ and tvOS 15+.

### In Swift Package

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/SwiftedMind/Queryable", from: "1.0.0")
```

### In Xcode project

Go to `File` > `Add Packages...` and enter the URL "https://github.com/SwiftedMind/Queryable" into the search field at the top right. Queryable should appear in the list. Select it and click "Add Package" in the bottom right.

### Usage

To use, simply import the `Queryable` target in your code.

```swift
import SwiftUI
import Queryable

struct ContentView: View {
  @Queryable<Void, Bool> var buttonConfirmation
  /* ... */
}
```

## Get Started

To best explain what `Queryable` does, let's look at an example. Say we have a button whose action needs a confirmation by the user. The confirmation should be presented as an alert with two buttons. 

Usually, you would implement this in a way similar to the following:

```swift
import SwiftUI

struct ContentView: View {
  @State private var isShowingConfirmationAlert = false

  var body: some View {
    Button("Do it!") {
      isShowingConfirmationAlert = true
    }
    .alert(
      "Do you really want to do this?",
      isPresented: $isShowingConfirmationAlert
    ) {
      Button("Yes") { confirmAction(true) }
      Button("No") { confirmAction(false) }
    } message: {}
  }

  @MainActor private func confirmAction(_ confirmed: Bool) {
    print(confirmed)
  }
}
```

The code is fairly simple. We toggle the alert presentation whenever the button is pressed and then call `confirmAction(_:)` with the answer the user has given. There's nothing wrong with this approach, it works perfectly fine.

However, I believe there is a much more convenient way of doing it. If you think about it, triggering the presentation of an alert and waiting for some kind of result – the user's confirmation in this case – is basically just an asynchronous operation. In Swift, there's a mechanism for that: *Swift Concurrency*.

Wouldn't it be awesome if we could simply `await` the confirmation and get the result as the return value of a single `async` function call? Something like this:

```swift
import SwiftUI

struct ContentView: View {
  // Some property that takes care of the view presentation
  var buttonConfirmation: /* ?? */

  var body: some View {
    Button("Do it!") {
      confirm()
    }
    .alert(
      "Do you really want to do this?",
      isPresented: /* ?? */
    ) {
      Button("Yes") { /* ?? */ }
      Button("No") { /* ?? */ }
    } message: {}
  }

  @MainActor private func confirm() {
    Task {
      do {
        // Suspend, show the alert and resume with the user's answer
        let isConfirmed = try await buttonConfirmation.query()
      } catch {}
    }
  }
}
```

The idea is that this `query()` method would suspend the current task, somehow toggle the presentation of the alert and then resume with the result, all without us ever leaving the scope. The entire user interaction with the UI is contained in this single line.

And that is exactly what `Queryable` does. It's a property wrapper that you can add within any SwiftUI `View` to control view presentations from asynchronous contexts. Here's what it looks like:

```swift
import SwiftUI
import Queryable

struct ContentView: View {
  // Since we don't need to provide data with the confirmation, we pass `Void` as the Input.
  // The Result type should be a Bool.
  @Queryable<Void, Bool> var buttonConfirmation

  var body: some View {
    Button("Commit") {
      confirm()
    }
    .queryableAlert( // Special alert modifier whose presentation is controlled by a Queryable
      controlledBy: buttonConfirmation,
      title: "Do you really want to do this?"
      ) { item, query in
        // The provided query type lets us return a result
        Button("Yes") { query.answer(with: true) }
        Button("No") { query.answer(with: false) }
      } message: {_ in}
  }

  @MainActor
  private func confirm() {
    Task {
      do {
        let isConfirmed = try await buttonConfirmation.query()
        // Do something with the result
      } catch {}
    }
  }
}
```

In my opinion, this looks and feels much cleaner and a lot more convenient. As a bonus, we can now reuse the alert for all kinds of things, since it doesn't know anything about its context.

> **Note**
> 
> It is your responsibility to make sure that every query is answered at some point (unless cancelled, see [below](#cancelling-queries)). Failing to do so will cause undefined behavior and possibly crashes. This is because `Queryable` uses `Continuations` under the hood.

### Passing Down The View Hierarchy

Another interesting thing you can do with `Queryable` is pass it down the view hierarchy. In the following example, `MyChildView` has no idea about the alert from `ContentView`, but it still can query a confirmation and receive a result. If you later swap out the `alert` for a `confirmationDialog` in `ContentView`, nothing changes for `MyChildView`.

```swift
import SwiftUI
import Queryable

struct MyChildView: View {
  // Passed from a parent view
  var buttonConfirmation: Queryable<Void, Bool>.Trigger

  var body: some View {
    Button("Confirm Here Instead") {
      confirm()
    }
  }

  @MainActor
  private func confirm() {
    Task {
      do {
        // This view has no idea how the confirmation is obtained. It doesn't need to!
        let isConfirmed = try await buttonConfirmation.query()
        // Do something with the result
      } catch {}
    }
  }
}
```

### Providing an Input Value

In the examples above, we've used `Void` as the generic `Input` type for `Queryable`, since the confirmation alert didn't need it. But we can pass any value type we want.

For example, let's say we want to present a sheet on which the user can create a new `PlayerItem` that we then save in a database (or send to a backend). By querying with an input of type `PlayerItem`, we can provide the `PlayerEditor` view with data to pre-fill some of the inputs in the form.

```swift
struct PlayerItem {
  var name: String
  /* ... */
  
  static var draft: PlayerItem {/* ... */}
}

struct PlayerListView: View {
  @Queryable<PlayerItem, PlayerItem> var playerCreation
  
  var body: some View {
    /* ... */
      .queryableSheet(controlledBy: playerCreation) { playerDraft, query in
        PlayerEditor(draft: playerDraft, onCompletion: { player in
          query.answer(with: player)
        })
    }
  }

  @MainActor
  private func createPlayer() {
    Task {
      do {
        let createdPlayer = try await buttonConfirmation.query(with: PlayerItem.draft)
        // Store player in database, for example
      } catch {}
    }
  }
}
```

This can be incredibly handy.

### Cancelling Queries

There are a few ways an ongoing query is cancelled.

- You call the `cancel()` method on the `Queryable` property, for instance `buttonConfiguration.cancel()`.
- The `Task` that calls the `query()` method is cancelled. When this happens, the query will automatically be cancelled and end the view presentation.
- The view is dismissed by the system or the user (by swiping down a sheet, for example). The `Queryable` will detect this and cancel any ongoing queries.
- A new query is started while another one is ongoing. This will either cancel the new one or the ongoing one, depending on the specified [conflict policy](#handling-conflicts).

In all of the above cases, a `QueryCancellationError` will be thrown.

### Handling Conflicts

If you try to start a query while another one is already ongoing, there will be a conflict. The default behavior in that situation is for the previous query to be cancelled. You can alter that by specifying a `QueryConflictPolicy` for you `Queryable`, like so:

```swift
@Queryable<Void, Bool>(queryConflictPolicy: .cancelNewQuery) var buttonConfirmation
@Queryable<Void, Bool>(queryConflictPolicy: .cancelPreviousQuery) var otherButtonConfirmation
```


## Supported Queryable Modifiers

Currently, these are the view modifiers that support being controlled by a `Queryable`:

- `queryableAlert(controlledBy:title:actions:message)`
- `queryableConfirmationDialog(controlledBy:title:actions:message)`
- `queryableFullScreenCover(controlledBy:onDismiss:content:)`
- `queryableSheet(controlledBy:onDismiss:content:)`
- `queryableOverlay(controlledBy:animation:alignment:content:)`
- `queryableClosure(controlledBy:block:)`


## License

MIT License

Copyright (c) 2023 Dennis Müller and all collaborators

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
