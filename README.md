# 3d-models

OpenSCAD model workspace for agents and humans.

## Layout

Each model group lives in its own top-level folder and contains only these
subfolders:

```text
thing-name/
  models/   # .scad source files
  renders/  # generated .png previews
  outputs/  # generated .stl exports
```

Do not put files directly in a model group root. Put OpenSCAD source under
`models/`; `make` writes artifacts to the sibling `renders/` and `outputs/`
directories.

## Usage

Create a new group:

```sh
make init NAME=thing-name
```

Render and export everything:

```sh
make
```

Useful targets:

```sh
make list
make lint
make stls
make renders
make clean
```

The Makefile discovers every `*/models/*.scad` file. For each source it writes:

- `group/outputs/name.stl`
- `group/renders/name-iso.png`
- `group/renders/name-front.png`
- `group/renders/name-top.png`
- `group/renders/name-right.png`

If `openscad` is not on `PATH`, pass it explicitly:

```sh
make OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
```
