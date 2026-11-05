#!/usr/bin/env bash
# Updates the `tz` submodule to a release tag and regenerates
# `chrono_timezone/lib/src/time_zones.dart`.
#
# Usage: scripts/update_tz_data.sh [tag]
#
# Without `tag`, the latest release tag (e.g., `2026f`) is used.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tz="$root/chrono_timezone/tz"

git -C "$tz" fetch --tags origin

tag="${1:-$(git -C "$tz" tag --list '[0-9][0-9][0-9][0-9][a-z]' --sort=-v:refname | head -n 1)}"
if [[ -z "$tag" ]]; then
  echo 'Could not determine a tz release tag.' >&2
  exit 1
fi

echo "Checking out tz $tag"
git -C "$tz" checkout --quiet "$tag"

(cd "$root/chrono_timezone_builder" && dart pub get)
# The builder reads `tz/` and writes `lib/src/time_zones.dart` relative to the
# current directory.
(cd "$root/chrono_timezone" && dart run ../chrono_timezone_builder/bin/build.dart)

echo "Done. Review and commit the submodule update and time_zones.dart."
