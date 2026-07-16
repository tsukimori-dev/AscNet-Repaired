# AscNet Repaired — sanitized source snapshot

This branch is a source-only research snapshot of AscNet compatibility repairs. It is intentionally **not a ready-to-run private-server bundle** and is not an official Punishing: Gray Raven project.

## Public-snapshot boundary

The public tree deliberately excludes:

- game executables, launchers, databases, saves, packet captures, logs, and build artifacts;
- account tokens, login-cache helpers, local credentials, and workstation-specific paths;
- proxy/traffic-redirection scripts and unattended account-creation helpers;
- deployment reports, process identifiers, local hashes, and runtime evidence;
- client artwork, notices, response captures, gameplay configuration dumps, and gameplay table rows.

`Schemas/table/` contains only column names plus synthetic `0` / `sample` rows. These files exist solely so the source generator can produce compile-time table types. They are not gameplay data and cannot make the server playable.

Real runtime material belongs under the ignored `Resources/` directories and must be obtained and used lawfully by the operator. Do not commit it to this repository.

## Security defaults

- The SDK/HTTP host defaults to loopback.
- The game TCP listener now defaults to `127.0.0.1`.
- A non-loopback game bind requires both an explicit `ASCNET_GAME_BIND_ADDRESS` and `ASCNET_ALLOW_REMOTE_BIND=1`.
- The snapshot must not be exposed directly to the internet. It has not been reviewed or hardened as a production service.

## Build

.NET 8 is required.

```powershell
dotnet build .\AscNet\AscNet.csproj -c Release
dotnet build .\AscNet.Test\AscNet.Test.csproj -c Release
```

This validates the source and schema-only generator inputs. Running gameplay additionally requires a private local runtime data pack that is not distributed here.

Before publishing any change, run:

```powershell
pwsh -File .\tools\verify-public-snapshot.ps1
```

CI performs the same safety check and a Release build.

## Scope of the repair source

The retained code covers current-client protocol compatibility and local gameplay-handler repairs, including progression, equipment, profile cosmetics, boss modes, and mapping-battle flow. It does not claim official-server parity, official ranking services, or production security.

## Licensing and rights

The upstream repositories do not currently provide an explicit `LICENSE` file. This snapshot therefore does not add or imply an open-source license for upstream code. Public visibility is not a grant of rights to game assets, client data, trademarks, or other third-party material. The GitHub fork relationship is retained for attribution and provenance.

See [SECURITY.md](SECURITY.md) for safe reporting guidance.
