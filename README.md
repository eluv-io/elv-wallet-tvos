# Eluvio Media Wallet for tvOS

Eluvio Media Wallet on Apple TV.

For a detailed walkthrough of customizing and running this app in single property mode, see [Customize.md](Customize.md).

## Key Patterns

- **Stores as single source of truth**: `PropertyStore`, `AccountStore`, etc. hold app state. Views read from stores rather than making API calls directly.
- **Router-based navigation**: A `Router` with a `NavigationStack` and typed `NavDestination` enum handles all navigation.
- **Persistent caching**: `PersistentDataCache` caches API responses to disk, making subsequent launches fast.
- **Permission resolution**: `PermissionResolver` checks content access before displaying items.
- **`@Observable` state**: Stores use Swift Observation for reactive UI updates.
