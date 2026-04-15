# Eluvio Media Wallet for tvOS

Eluvio Media Wallet on Apple TV.

For a detailed walkthrough of customizing and running this app in single property mode, see [Customize.md](Customize.md).

## Firebase configuration

The build works fine without `GoogleService-Info.plist` — Firebase is just disabled at runtime.

If you want Firebase enabled (Eluvio team only), fetch the plist file using:
```bash
bin/fetch-secrets.sh
```

## Key Patterns

- **Stores as single source of truth**: `PropertyStore`, `AccountStore`, etc. hold app state. Views read from stores rather than making API calls directly.
- **Router-based navigation**: A `Router` with a `NavigationStack` and typed `NavDestination` enum handles all navigation.
- **Persistent caching**: `PersistentDataCache` caches API responses to disk, making subsequent launches fast.
- **Permission resolution**: `PermissionResolver` checks content access before displaying items.
- **`@Observable` state**: Stores use Swift Observation for reactive UI updates.
