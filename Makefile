# =============================================================================
# HCMUT_DICD -- top-level command dispatcher.
#
# Almost everything runs INSIDE the pinned EDA container, so the only thing you
# need on the host is Docker. See docs/00-getting-started.md.
# =============================================================================
SHELL := /bin/bash

# Pick up env/.env automatically if the student created one.
ENV_FILE    := $(wildcard env/.env)
COMPOSE_ENV := $(if $(ENV_FILE),--env-file env/.env,)
COMPOSE     := docker compose $(COMPOSE_ENV) -f env/docker-compose.yml
EDA_IMAGE   ?= hpretl/iic-osic-tools:2026.05

# Run a shell command inside the container, at the repo root.
IN_CONTAINER = $(COMPOSE) run --rm eda bash -lc

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "HCMUT_DICD -- open-source RTL-to-GDSII course"
	@echo ""
	@echo "Environment (host needs only Docker):"
	@echo "  make image-pull   Pull the pinned EDA image ($(EDA_IMAGE))"
	@echo "  make shell        Interactive shell inside the container"
	@echo "  make env-up       Start the browser (noVNC) desktop for GUI tools"
	@echo "  make env-down     Stop the desktop"
	@echo "  make healthcheck  Print every tool's version (verify the setup)"
	@echo ""
	@echo "Flow:"
	@echo "  make smoke        One-command toolchain smoke test (tiny design -> GDS)"
	@echo "  make hw1 ... hw5  Run a homework's default target in-container"
	@echo "  make final        Run the final project's default target"
	@echo "  make clean        Remove build/run artifacts repo-wide"

.PHONY: image-pull
image-pull:
	docker pull $(EDA_IMAGE)

.PHONY: shell
shell:
	$(COMPOSE) run --rm --service-ports eda bash

.PHONY: env-up
env-up:
	$(COMPOSE) up -d
	@echo "Desktop: http://localhost:$${NOVNC_PORT:-8888}   (VNC password: $${VNC_PW:-hcmut})"

.PHONY: env-down
env-down:
	$(COMPOSE) down

.PHONY: healthcheck
healthcheck:
	$(IN_CONTAINER) 'bash env/scripts/healthcheck.sh'

.PHONY: smoke
smoke:
	$(IN_CONTAINER) 'cd smoke && make all'

.PHONY: hw1 hw2 hw3 hw4 hw5
hw1 hw2 hw3 hw4 hw5:
	$(IN_CONTAINER) 'cd hw/$@-* && make'

.PHONY: final
final:
	$(IN_CONTAINER) 'cd final-project && make'

.PHONY: clean
clean:
	bash scripts/clean-all.sh
