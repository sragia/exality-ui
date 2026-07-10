#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PACKAGER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bigwigs-packager"

if ! command -v svn &>/dev/null; then
	for dir in \
		"/c/Program Files/SlikSvn/bin" \
		"/c/Program Files/TortoiseSVN/bin" \
		"/c/Program Files (x86)/SlikSvn/bin" \
		"/c/Program Files (x86)/TortoiseSVN/bin"; do
		if [[ -x "$dir/svn.exe" ]]; then
			export PATH="$dir:$PATH"
			break
		fi
	done
fi

if ! command -v svn &>/dev/null; then
	echo "ERROR: svn is required to fetch several libraries from .pkgmeta."
	echo "Install it with: winget install Slik.Subversion"
	exit 1
fi

if [[ ! -f "$PACKAGER_DIR/release.sh" ]]; then
	echo "Cloning BigWigs packager..."
	git clone --depth 1 https://github.com/BigWigsMods/packager.git "$PACKAGER_DIR"
else
	echo "Updating BigWigs packager..."
	git -C "$PACKAGER_DIR" pull --ff-only
fi

cd "$ROOT"

RELEASE_LIBS="$ROOT/.release/ExalityUI/Libs"
if [[ -d "$RELEASE_LIBS" ]]; then
	echo "Cleaning $RELEASE_LIBS..."
	rm -rf "$RELEASE_LIBS"
fi

"$PACKAGER_DIR/release.sh" -d -z -o

LIBS_SRC="$ROOT/.release/ExalityUI/Libs"
LIBS_DST="$ROOT/ExalityUI/Libs"

if [[ ! -d "$LIBS_SRC" ]]; then
	echo "ERROR: Packaged libs not found at $LIBS_SRC"
	exit 1
fi

echo "Copying libs to ExalityUI/Libs..."
rm -rf "$LIBS_DST"
cp -a "$LIBS_SRC" "$LIBS_DST"
echo "Done."
