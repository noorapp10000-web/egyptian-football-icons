---
name: GitHub push authentication
description: Safe authentication pattern for pushing to the project repository from the Replit workspace.
---

Use a temporary HTTP Basic Authorization header built from `x-access-token` and the workspace GitHub secret when pushing. Do not put the token in the remote URL, credential helper output, files, or chat.

**Why:** GitHub accepted the token through its API and repository permissions, but rejected Bearer/askpass Git attempts; an askpass mistake can also echo the secret into tool output.

**How to apply:** Build the Basic header in a shell variable, run the push, then verify the remote branch. If a token appears in output, treat it as compromised and rotate it before retrying.