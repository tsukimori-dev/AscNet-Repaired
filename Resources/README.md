# Local runtime resources

This directory is intentionally empty in the public snapshot.

For private local testing, the application expects compatible material in directories such as:

```text
Resources/Configs/
Resources/Data/
Resources/table/
```

Those paths are ignored by Git. Do not publish client-derived tables, artwork, captured responses, account material, saves, or deployment evidence.

The versioned `Schemas/table/` tree is compile-time metadata only and must not be copied into the runtime resource directory.
