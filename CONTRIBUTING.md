# Publishing `thinking_orbs` to pub.dev

Publishing is automated via GitHub Actions using pub.dev's OIDC-based
"Automated publishing" — no long-lived tokens are stored in this repo.
That automation has to be switched on once, and it can only be switched
on for a package that already exists on pub.dev, so the very first
release has to be published by hand.

## One-time setup

### 1. First release — manual

From a clean checkout, as the account that should own the package on
pub.dev (this opens an interactive Google OAuth flow in your browser):

```bash
flutter pub get
dart pub publish --dry-run   # sanity check: 0 warnings expected
dart pub publish
```

This creates `thinking_orbs` on pub.dev and makes you its owner/uploader.

### 2. Enable automated publishing on pub.dev

1. Sign in to <https://pub.dev/packages/thinking_orbs/admin>.
2. Under **Automated publishing**, enable **Publishing from GitHub
   Actions**.
3. Repository: `leofmarciano/thinking_orbs`.
4. Tag pattern: `v{{version}}` (matches tags like `v0.2.0`).
5. (Optional, recommended) Restrict publishing to a GitHub **Environment**
   named `pub.dev` — create it under repo Settings → Environments, add
   required reviewers, and add `environment: pub.dev` to the `publish`
   job in [.github/workflows/publish.yml](.github/workflows/publish.yml).

## Every subsequent release

1. Bump `version:` in [pubspec.yaml](pubspec.yaml) and add an entry to
   [CHANGELOG.md](CHANGELOG.md).
2. Commit, then tag and push the tag — this is what triggers the
   `Publish to pub.dev` workflow:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. Watch the run under the repo's **Actions** tab (approve the
   `pub.dev` environment deployment if step 2.5 above was configured).
4. Confirm the new version on
   <https://pub.dev/packages/thinking_orbs/versions>.

If automated publishing is ever unavailable, an authorized uploader can
always fall back to publishing by hand from a clean checkout of the
tagged commit (same three commands as step 1 above, minus `--dry-run`).
