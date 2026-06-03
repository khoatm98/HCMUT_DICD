# =============================================================================
# HCMUT_DICD -- top-level command dispatcher.
#
# Two ways to get the toolchain (pick with EDA_ENV):
#   EDA_ENV=docker  (default)  run everything inside the pinned EDA container
#   EDA_ENV=conda              run in a local conda env (Linux; no Docker/root)
#   EDA_ENV=native             tools already on your PATH (advanced)
#
# Examples:
#   make image-pull && make smoke              # Docker
#   bash env/conda/setup.sh && make smoke EDA_ENV=conda
# =============================================================================
SHELL := /bin/bash

EDA_ENV   ?= docker
CONDA_ENV ?= hcmut-eda
EDA_IMAGE ?= hpretl/iic-osic-tools:2026.05

# ---- Docker plumbing ----
ENV_FILE    := $(wildcard env/docker/.env)
COMPOSE_ENV := $(if $(ENV_FILE),--env-file env/docker/.env,)
COMPOSE     := docker compose $(COMPOSE_ENV) -f env/docker/docker-compose.yml

# ---- RUN: how to execute a shell command in the selected environment ----
ifeq ($(EDA_ENV),docker)
  RUN          = $(COMPOSE) run --rm eda bash -lc
  SMOKE_TARGET = all
else ifeq ($(EDA_ENV),conda)
  RUN          = conda run --no-capture-output -n $(CONDA_ENV) bash -lc
  SMOKE_TARGET = front
else                       # native
  RUN          = bash -lc
  SMOKE_TARGET = front
endif

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "HCMUT_DICD -- open-source RTL-to-GDSII course   (EDA_ENV=$(EDA_ENV))"
	@echo ""
	@echo "Docker environment:"
	@echo "  make image-pull    Pull the pinned EDA image ($(EDA_IMAGE))"
	@echo "  make shell         Interactive shell inside the container"
	@echo "  make env-up        Start the browser (noVNC) desktop for GUI tools"
	@echo "  make env-down      Stop the desktop"
	@echo ""
	@echo "Conda environment (Linux; no Docker):"
	@echo "  bash env/conda/setup.sh        Create the conda env 'hcmut-eda'"
	@echo "  make <target> EDA_ENV=conda    Run any target in the conda env"
	@echo ""
	@echo "Common (respect EDA_ENV):"
	@echo "  make healthcheck   Print every tool's version (verify the setup)"
	@echo "  make smoke         Toolchain smoke test (Docker: full; conda: front-end)"
	@echo "  make hw1 ... hw5   Run a homework's default target"
	@echo "  make final         Run the final project's default target"
	@echo "  make clean         Remove build/run artifacts repo-wide"

# ---- Docker-only targets ----
.PHONY: image-pull shell env-up env-down
image-pull:
	docker pull $(EDA_IMAGE)
shell:
	$(COMPOSE) run --rm --service-ports eda bash
env-up:
	$(COMPOSE) up -d
	@echo "Desktop: http://localhost:$${NOVNC_PORT:-8888}   (VNC password: $${VNC_PW:-hcmut})"
env-down:
	$(COMPOSE) down

# ---- Conda helper ----
.PHONY: conda-setup
conda-setup:
	bash env/conda/setup.sh $(CONDA_ENV)

# ---- Environment-agnostic flow targets ----
.PHONY: healthcheck smoke hw1 hw2 hw3 hw4 hw5 final clean
healthcheck:
	$(RUN) 'bash env/scripts/healthcheck.sh'
smoke:
	$(RUN) 'cd smoke && make $(SMOKE_TARGET)'
# Front-end functional sim lives in each module's 01_RTL/ (CVSD stage dirs).
hw1 hw2 hw3 hw4:
	$(RUN) 'cd hw/$@-*/01_RTL && make'
# HW5 is APR only (04_APR/).
hw5:
	$(RUN) 'cd hw/hw5-apr/04_APR && make'
# Final: run the functional sim from 01_RTL once you've written the RTL; the
# back-end stages (02_SYN/03_GATE/04_APR/06_POWER) are run per-stage dir.
final:
	$(RUN) 'cd final-project/01_RTL && make'
clean:
	bash scripts/clean-all.sh
