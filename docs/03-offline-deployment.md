# Offline / low-bandwidth deployment

This course is designed for institutions where **reliable internet to Docker Hub
or GitHub cannot be assumed**. The goal: a class of N students should require
**one** download from the internet (by an instructor/admin), after which every
student installs from the **local network or a USB drive** — zero per-student
internet.

Because the SKY130 PDK is **baked into the image**, there is no separate
multi-GB PDK download to mirror. You mirror exactly one artifact: the image.

| Artifact | Size | Who fetches it |
|----------|------|----------------|
| `hpretl/iic-osic-tools:2026.05` (tools + PDK) | ~4 GB compressed / ~20 GB disk | admin, **once** |
| Per-student internet | **0 GB** | — |

---

## Option A — `docker save` tarball (simplest, fully air-gapped)

Best for handing out via USB or a simple HTTP/SMB file share.

**Admin, once, on a connected machine:**

```bash
docker pull hpretl/iic-osic-tools:2026.05
docker save hpretl/iic-osic-tools:2026.05 | gzip > iic-osic-tools-2026.05.tar.gz
sha256sum iic-osic-tools-2026.05.tar.gz > iic-osic-tools-2026.05.sha256
# host both files on a campus share, or copy to USB drives
```

**Each student (no internet needed):**

```bash
# fetch from the LAN share (or copy from USB)
curl -O http://mirror.campus.local/eda/iic-osic-tools-2026.05.tar.gz
curl -O http://mirror.campus.local/eda/iic-osic-tools-2026.05.sha256
sha256sum -c iic-osic-tools-2026.05.sha256          # verify integrity
gunzip -c iic-osic-tools-2026.05.tar.gz | docker load
```

That single load makes the student fully offline-capable (PDK included). Then
`make smoke` works with no network.

A helper wraps the admin side:

```bash
bash scripts/fetch-offline-bundle.sh        # pulls + saves + checksums the image
```

---

## Option B — Local registry mirror (best for a managed lab)

Better when you have many lab machines and want `docker pull` to "just work"
against a LAN server.

**Admin (run a registry on the LAN):**

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
docker tag  hpretl/iic-osic-tools:2026.05 mirror.campus.local:5000/iic-osic-tools:2026.05
docker push mirror.campus.local:5000/iic-osic-tools:2026.05
```

**Each student:**

```bash
docker pull mirror.campus.local:5000/iic-osic-tools:2026.05
```

Then point the course at the mirror without editing tracked files:

```bash
cp env/.env.example env/.env
# edit env/.env:
#   EDA_IMAGE=mirror.campus.local:5000/iic-osic-tools:2026.05
```

The same `docker-compose.yml` now works online or offline (it reads
`${EDA_IMAGE}`).

> If the registry has no TLS, add it to `insecure-registries` in each machine's
> `/etc/docker/daemon.json` and restart Docker.

---

## Option C — conda, offline (no Docker)

If you use the conda path (`env/conda/`), there's no image to mirror. Two ways
to avoid per-student internet:

**C1 — `conda-pack` a solved environment into a tarball (simplest):**

```bash
# admin, once, on a connected Linux machine:
bash env/conda/setup.sh
conda install -n hcmut-eda conda-pack -c conda-forge
conda pack -n hcmut-eda -o hcmut-eda.tar.gz      # ~few GB, PDK included

# each student (no internet):
mkdir -p ~/hcmut-eda && tar -xzf hcmut-eda.tar.gz -C ~/hcmut-eda
source ~/hcmut-eda/bin/activate
conda-unpack
export EDA_ENV=conda        # then: make smoke EDA_ENV=conda
```

**C2 — mirror the channels on the LAN:** mirror `litex-hub` + `conda-forge`
(e.g. with `conda-mirror` or a local file/HTTP channel) and point conda at them
with `--channel file:///srv/channels/...`. Pin builds via the exported
`conda-lock.yml` so every student resolves the identical versions.

## Mirroring the repository itself

The course repo is small (text + RTL). Distribute it by any means: a campus Git
server, a release `.zip`, or USB. Nothing in the labs requires cloning from
GitHub at run time.

---

## Reproducibility checklist (do this at course start)

1. Pin the image **tag** in `VERSIONS.lock` (done: `2026.05`).
2. Record the image **digest** (`docker inspect ... RepoDigests`) in
   `VERSIONS.lock` so a re-pull years later is byte-identical.
3. Keep the `.sha256` next to any `docker save` tarball you distribute.
4. **Do not upgrade the image mid-semester** — a new tag can change tool
   versions and shift area/timing/power numbers, breaking grade comparability.

With the tag + digest pinned and the image mirrored locally, the whole flow is
reproducible offline, on every student's machine, for the life of the course.
