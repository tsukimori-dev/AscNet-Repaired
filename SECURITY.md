# Security policy

This repository is a local research project, not an internet-facing service.

Please report suspected credential exposure or an unsafe default privately to the repository owner. Do not include live tokens, passwords, account caches, save files, packet captures, or unredacted logs in an issue.

If a credential is ever committed, treat it as compromised: revoke or rotate it first, then remove it from reachable refs and contact GitHub Support when repository-network object removal is required. Deleting a branch alone is not a complete secret-removal procedure.

The public snapshot accepts fixes for:

- accidental tracking of runtime/private material;
- non-loopback default bindings;
- authentication bypasses reachable outside loopback;
- logs that disclose secrets or personal information;
- safety-verifier bypasses.
