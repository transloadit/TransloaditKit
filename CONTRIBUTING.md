# Contributing

Build and run the tests on macOS with Xcode installed:

```sh
swift build
swift test
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

### CocoaPods publication

Use a macOS machine with Xcode and CocoaPods installed. A pod owner must run
`pod trunk register` with their pod-owner email address on that machine and
confirm the session through the verification email. Run `pod trunk me` to
confirm the session is verified and lists `Transloadit` before pushing.

The [3.6.0 release on trunk](https://trunk.cocoapods.org/api/v1/pods/Transloadit/versions/3.6.0)
was published on `studio1` with CocoaPods 1.17.0 and Xcode 27.0. Connect with
`ssh studio1`, then use its clean repository checkout:

```sh
cd ~/code/TransloaditKit && (
  set -e
  pod trunk me
  RELEASE_VERSION=3.6.0
  RELEASE_COMMIT=d6628f3d7fe5b90bc8271f4912d7cadb25360a27
  test -z "$(git status --porcelain=v1)"
  git fetch origin main --tags
  git checkout --detach "$RELEASE_VERSION"
  test "$(git rev-parse HEAD)" = "$RELEASE_COMMIT"
)
```

Publish with `pod trunk push Transloadit.podspec` when the Xcode toolchain supports
the podspec's deployment targets.

For 3.6.0, the plain push failed because Xcode 27 rejected the podspec's iOS 10.0
and macOS 10.11 deployment targets. It also warned that the referenced `LICENSE`
file is missing and that an existing `identifier` binding is unused. The
successful push used a temporary build configuration with Xcode's supported
deployment targets and allowed those existing warnings:

```sh
(
  set -e
  RELEASE_VALIDATION_DIR="$(mktemp -d -t transloaditkit-release)"
  trap 'rm -f "$RELEASE_VALIDATION_DIR/validation.xcconfig"; rmdir "$RELEASE_VALIDATION_DIR"' EXIT
  cat > "$RELEASE_VALIDATION_DIR/validation.xcconfig" <<'XCCONFIG'
IPHONEOS_DEPLOYMENT_TARGET = 15.0
MACOSX_DEPLOYMENT_TARGET = 12.0
XCCONFIG
  XCODE_XCCONFIG_FILE="$RELEASE_VALIDATION_DIR/validation.xcconfig" \
    pod trunk push Transloadit.podspec --allow-warnings
)
```

This override applies only to the validation build. The published podspec still
comes from the release tag; build and import validation remain enabled.
It validates iOS 15.0 and macOS 12.0, rather than the older deployment targets
declared by the podspec.

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
