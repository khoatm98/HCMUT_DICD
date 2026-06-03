#!/usr/bin/env bash
# Host-side preflight: do you have what you need to START the course?
# (The EDA tools themselves live in the container; this only checks the host.)
set -u
ok=1
need() {
    printf "  %-8s " "$1"
    if command -v "$1" >/dev/null 2>&1; then
        echo "OK  ($("$1" --version 2>&1 | head -1))"
    else
        echo "MISSING"; ok=0
    fi
}
echo "== Host preflight =="
need docker
need git
need make
printf "  %-8s " "daemon"
if docker info >/dev/null 2>&1; then echo "docker daemon running"
else echo "docker daemon NOT running (start Docker Desktop / dockerd)"; ok=0; fi
echo
if [ $ok -eq 1 ]; then
    echo "All good. Next:  make image-pull && make smoke"
else
    echo "Install the MISSING items above, then re-run this script."
    exit 1
fi
