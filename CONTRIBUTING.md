# Contributing

Build, run the tests, and validate the pod on macOS with Xcode and CocoaPods installed:

```sh
swift build
swift test
pod lib lint Transloadit.podspec
```

## Releasing

Release preparation and publication are separate steps. Prepare a PR that:

- Updates `s.version` in `Transloadit.podspec`.
- Updates `TransloaditAPI.clientHeader` in `Sources/TransloaditKit/TransloaditAPI.swift` to the same version.
- Moves the release notes from `## Next` into a `## VERSION` section in `CHANGELOG.md`, leaving `## Next` for future changes.

Merge the preparation PR into `main` and confirm its build and tests pass before publishing.
For 3.6.0, the preparation PR was #47 and the merged commit was
`d6628f3d7fe5b90bc8271f4912d7cadb25360a27`.

### Tag and GitHub release

The commands below show 3.6.0. For a new release, replace the version and commit
with those from its merged preparation PR. From the repository checkout, create
an annotated tag and use the matching changelog section, including its heading,
as the GitHub release body. Continue only after each command block succeeds.

```sh
(
  set -e
  RELEASE_VERSION=3.6.0
  RELEASE_COMMIT=d6628f3d7fe5b90bc8271f4912d7cadb25360a27
  git fetch origin main --tags
  git merge-base --is-ancestor "$RELEASE_COMMIT" origin/main
  git tag -a "$RELEASE_VERSION" "$RELEASE_COMMIT" -m "$RELEASE_VERSION"
  git push origin "refs/tags/$RELEASE_VERSION"

  RELEASE_NOTES="$(mktemp)"
  trap 'rm -f "$RELEASE_NOTES"' EXIT
  git show "$RELEASE_COMMIT:CHANGELOG.md" | awk -v version="$RELEASE_VERSION" '
    /^## / {
      if (release) exit
      release = ($0 == "## " version)
    }
    release { print }
  ' > "$RELEASE_NOTES"
  test -s "$RELEASE_NOTES"
  gh release create "$RELEASE_VERSION" --repo transloadit/TransloaditKit \
    --verify-tag --title "$RELEASE_VERSION" --notes-file "$RELEASE_NOTES"
)
```

Confirm the published release has the expected notes and that the tag points to
the merged preparation commit.

If the tag was pushed but GitHub release creation failed, fetch the tags and
confirm `git rev-parse 3.6.0^{commit}` matches the preparation commit. Rerun the
block with the `git tag -a` line omitted. If the release already exists, inspect
it with `gh release view 3.6.0` instead of recreating it.

### CocoaPods publication

Publication requires Kevin's approval after the release preparation PR is merged.

Use a macOS machine with Xcode and CocoaPods installed. A pod owner must run
`pod trunk register` with their pod-owner email address on that machine and
confirm the session through the verification email. Run `pod trunk me` to
confirm the session is verified and lists `Transloadit` before pushing.

The [3.6.0 release on trunk](https://trunk.cocoapods.org/api/v1/pods/Transloadit/versions/3.6.0)
was published with CocoaPods 1.17.0 and Xcode 27.0. That release predates the
license and deployment-target fixes. Future releases declare iOS 15.0 and macOS
12.0 as their minimum supported versions.

Plain validation on Xcode 27 remains blocked by the published TUSKit 3.6.0
podspec's iOS 10.0 and macOS 10.11 targets. TUSKit 3.6.0 is the latest release
on CocoaPods; [3.7.0 removed CocoaPods support](https://github.com/tus/TUSKit/blob/3.7.0/CHANGELOG.md).
Resolve the dependency's deployment targets before publishing with this
toolchain, and require `pod lib lint Transloadit.podspec` to pass.

For a new release, replace both placeholders below with the version and commit
from its merged preparation PR. Use a clean repository checkout on a macOS
machine with Xcode and CocoaPods, and continue only if validation succeeds:

```sh
cd ~/code/TransloaditKit && (
  set -e
  pod trunk me
  RELEASE_VERSION=REPLACE_WITH_RELEASE_VERSION
  RELEASE_COMMIT=REPLACE_WITH_RELEASE_COMMIT
  test -z "$(git status --porcelain=v1)"
  git fetch origin main --tags
  git checkout --detach "$RELEASE_VERSION"
  test "$(git rev-parse HEAD)" = "$RELEASE_COMMIT"
  pod lib lint Transloadit.podspec
  pod trunk push Transloadit.podspec
)
```

The 3.6.0 push returned GitHub commit API timeouts despite completing publication.
Run `pod trunk info Transloadit` and confirm the version is absent before retrying
an interrupted push.

After a successful push, confirm the version is listed on trunk:

```sh
pod trunk info Transloadit
git switch main
```

A release is complete when its tag, GitHub release, and CocoaPods trunk version
are all published.
