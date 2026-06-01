# Agents

Each model group is a top-level folder with exactly:

```text
models/   # .scad source
renders/  # generated PNGs
outputs/  # generated STLs
```

Put `.scad` files only in `*/models/`. Do not put files in a model group root.

Use:

```sh
make init NAME=group-name
make
```

Before declaring a model complete:

1. Run `make lint`.
2. Run `make`.
3. Inspect the generated images in `*/renders/`.

Generated `renders/*.png` and `outputs/*.stl` files are build artifacts and
should not be committed.
