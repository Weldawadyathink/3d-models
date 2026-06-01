SHELL := /bin/bash

OPENSCAD ?= $(shell if command -v openscad >/dev/null 2>&1; then command -v openscad; elif [ -x /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD ]; then printf '%s\n' /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD; fi)

IMG_SIZE ?= 1400,1000
COLORSCHEME ?= Tomorrow
VIEWS ?= iso front top right
RENDER_JOBS ?= $(shell if command -v nproc >/dev/null 2>&1; then nproc; elif command -v sysctl >/dev/null 2>&1; then sysctl -n hw.ncpu; else printf '%s\n' 4; fi)

.DEFAULT_GOAL := all

.PHONY: all help check-openscad list init lint dirs stls renders render clean

all: dirs lint stls renders

help:
	@printf '%s\n' \
		'OpenSCAD model automation' \
		'' \
		'Targets:' \
		'  make              Validate layout, export STLs, and render PNGs.' \
		'  make stls         Export every */models/*.scad to */outputs/*.stl.' \
		'  make renders      Render PNG views into each group renders directory.' \
		'  make lint         Check project layout conventions.' \
		'  make dirs         Create missing renders/outputs dirs for model groups.' \
		'  make list         List discovered OpenSCAD source files.' \
		'  make init NAME=x  Create x/models, x/renders, and x/outputs.' \
		'  make clean        Remove generated STL and PNG files.' \
		'' \
		'Variables:' \
		'  OPENSCAD=/path/to/openscad' \
		'  IMG_SIZE=1400,1000' \
		'  COLORSCHEME=Tomorrow' \
		'  VIEWS="iso front top right"' \
		'  RENDER_JOBS=auto-detected CPU count'

check-openscad:
	@if [ -z "$(OPENSCAD)" ]; then \
		printf '%s\n' 'OpenSCAD was not found. Install it or run make OPENSCAD=/path/to/openscad.' >&2; \
		exit 1; \
	fi
	@'$(OPENSCAD)' --version >/dev/null

list:
	@find . -mindepth 3 -maxdepth 3 -path './*/models/*.scad' -type f | sort | sed 's#^\./##'

init:
	@if [ -z "$(NAME)" ]; then \
		printf '%s\n' 'Usage: make init NAME=folder-name' >&2; \
		exit 1; \
	fi
	@mkdir -p '$(NAME)'/models '$(NAME)'/renders '$(NAME)'/outputs

lint: dirs
	@set -euo pipefail; \
	bad_scad="$$(find . -path './.git' -prune -o -type f -name '*.scad' ! -path './*/models/*.scad' -print)"; \
	if [ -n "$$bad_scad" ]; then \
		printf '%s\n%s\n' 'OpenSCAD files must live under a group models directory:' "$$bad_scad" >&2; \
		exit 1; \
	fi; \
	bad_root_files="$$(find . -mindepth 2 -maxdepth 2 -path './.git/*' -prune -o -type f ! -name '.DS_Store' -print)"; \
	if [ -n "$$bad_root_files" ]; then \
		printf '%s\n%s\n' 'Model group roots must not contain files. Put source in models and generated artifacts in renders/outputs:' "$$bad_root_files" >&2; \
		exit 1; \
	fi; \
	while IFS= read -r models_dir; do \
		group="$${models_dir%/models}"; \
		bad_entries="$$(find "$$group" -mindepth 1 -maxdepth 1 ! -name models ! -name renders ! -name outputs ! -name '.DS_Store' -print)"; \
		if [ -n "$$bad_entries" ]; then \
			printf '%s\n%s\n' "$$group may only contain models/, renders/, and outputs/:" "$$bad_entries" >&2; \
			exit 1; \
		fi; \
		for required in renders outputs; do \
			if [ ! -d "$$group/$$required" ]; then \
				printf '%s\n' "$$group is missing $$required/" >&2; \
				exit 1; \
			fi; \
		done; \
	done < <(find . -mindepth 2 -maxdepth 2 -type d -name models | sort)

dirs:
	@set -euo pipefail; \
	while IFS= read -r models_dir; do \
		group="$${models_dir%/models}"; \
		mkdir -p "$$group/renders" "$$group/outputs"; \
	done < <(find . -mindepth 2 -maxdepth 2 -type d -name models | sort)

stls: check-openscad dirs
	@set -euo pipefail; \
	while IFS= read -r src; do \
		group="$${src#./}"; group="$${group%%/models/*}"; \
		name="$${src##*/}"; name="$${name%.scad}"; \
		out="$$group/outputs/$$name.stl"; \
		printf 'STL    %s -> %s\n' "$${src#./}" "$$out"; \
		'$(OPENSCAD)' -q --export-format asciistl -o "$$out" "$$src"; \
	done < <(find . -mindepth 3 -maxdepth 3 -path './*/models/*.scad' -type f | sort)

renders: check-openscad dirs
	@set -euo pipefail; \
	if ! [[ '$(RENDER_JOBS)' =~ ^[1-9][0-9]*$$ ]]; then \
		printf 'RENDER_JOBS must be a positive integer, got: %s\n' '$(RENDER_JOBS)' >&2; \
		exit 1; \
	fi; \
	find . -mindepth 3 -maxdepth 3 -path './*/models/*.scad' -type f | sort | while IFS= read -r src; do \
		group="$${src#./}"; group="$${group%%/models/*}"; \
		name="$${src##*/}"; name="$${name%.scad}"; \
		for view in $(VIEWS); do \
			case "$$view" in \
				iso) camera='0,0,0,60,0,35,180' ;; \
				front) camera='0,0,0,90,0,0,180' ;; \
				top) camera='0,0,0,0,0,0,180' ;; \
				right) camera='0,0,0,90,0,90,180' ;; \
				*) printf 'Unknown render view: %s\n' "$$view" >&2; exit 1 ;; \
			esac; \
			out="$$group/renders/$$name-$$view.png"; \
			printf '%s\0%s\0%s\0%s\0' "$$src" "$$out" "$$camera" "$${src#./}"; \
		done; \
	done | OPENSCAD_BIN='$(OPENSCAD)' IMG_SIZE_VALUE='$(IMG_SIZE)' COLORSCHEME_VALUE='$(COLORSCHEME)' xargs -0 -n 4 -P '$(RENDER_JOBS)' /bin/bash -c '\
		set -euo pipefail; \
		src="$$1"; out="$$2"; camera="$$3"; label="$$4"; \
		printf "PNG    %s -> %s\n" "$$label" "$$out"; \
		"$$OPENSCAD_BIN" -q --render true -o "$$out" --imgsize "$$IMG_SIZE_VALUE" --colorscheme "$$COLORSCHEME_VALUE" --autocenter --viewall --camera "$$camera" "$$src"; \
	' _

render: renders

clean:
	@find . -path './.git' -prune -o \( -path './*/renders/*.png' -o -path './*/outputs/*.stl' \) -type f -print -delete
