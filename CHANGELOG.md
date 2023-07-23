# Changelog

## 2.0.0

### New

- **Breaking:** The `@Queryable` property wrapper has been replaced by a `Queryable` class conforming to `ObservableObject`. This is an unfortunate breaking change, but it allows you to define Queryables literally *anywhere* in your app, i.e. in your views, view models or any other class your views have access to in some way. Please see the [Migration Guide]() for instructions on how to modify your existing code base. I'm sorry for the inconvenience of this, but I do believe it's going to be worth it.

- Added Unit Tests to reduce the chance of introducing bugs or broken functionality when making future modifications. The test suite will be continuously expanded.

### Changed

- **Breaking:** The logger configuration call has moved outside the generic class `Queryable` class to get rid off the awkward call `Queryable<Void, Void>.configureLog()`. The logger can now be configured via `QueryableLogger.configure()`.
