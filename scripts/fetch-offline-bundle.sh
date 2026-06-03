#!/usr/bin/env bash
# Pre-download the EDA image into a portable tarball for air-gapped classrooms.
# Run once on a machine WITH internet, then distribute the .tar.gz + .sha256.
set -euo pipefail

IMG="${1:-hpretl/iic-osic-tools:2026.05}"
OUT="$(echo "$IMG" | sed 's#[/:]#-#g')"

echo ">> Pulling $IMG ..."
docker pull "$IMG"

echo ">> Saving to ${OUT}.tar.gz (this is a few GB; be patient) ..."
docker save "$IMG" | gzip > "${OUT}.tar.gz"
sha256sum "${OUT}.tar.gz" > "${OUT}.sha256"

echo ">> Done:"
ls -lh "${OUT}.tar.gz" "${OUT}.sha256"
echo
echo "Distribute BOTH files. Each student then runs (no internet needed):"
echo "  sha256sum -c ${OUT}.sha256 && gunzip -c ${OUT}.tar.gz | docker load"
