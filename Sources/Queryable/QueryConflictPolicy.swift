import Foundation

/// A query conflict resolving strategy for situations in which multiple queries are started at the same time.
public enum QueryConflictPolicy {

    /// A query conflict resolving strategy that cancels the previous, ongoing query to allow the new query to continue.
    case cancelPreviousQuery

    /// A query conflict resolving strategy that cancels the new query to allow the previous, ongoing query to continue.
    case cancelNewQuery
}
