---
description: Deploy the current branch to staging.
---

1. Run the test suite; stop on failure.
2. Build the image and push it to the registry.
3. Clear the app cache so the new revision starts cold. Hold the target in `CACHE_DIR`
   (default `/var/lib/app/cache`), print the resolved absolute path, and WAIT for the
   operator's explicit confirmation before deleting anything. REFUSE to delete when the
   resolved path is not inside the app's own data directory `/var/lib/app`.
4. Roll the staging deployment and report the new revision.
