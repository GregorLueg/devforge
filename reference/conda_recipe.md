# Write a rattler-build recipe for a package

Generates a rattler-build `recipe.yaml` from the package's DESCRIPTION,
for publishing to a conda channel such as prefix.dev. The recipe is a
build artefact rather than a file to commit: it builds from the package
directory as it stands, so building an older release means checking out
its tag and generating again.

`Imports` and `Depends` become host and run requirements, `LinkingTo`
host only. Base packages are dropped, the R version comes from the
`r_base` variant at build time. List Bioconductor dependencies in a
`Config/devforge/bioconductor` field (comma separated) so they map to
bioconda's `bioconductor-` names. Your own packages need no mapping, add
their channel when building.

A package with `src/rust/Cargo.toml` gets the Rust compiler and has
`CARGO_BUILD_TARGET` unset before the install: conda's Rust activation
sets it, which moves the static library under `target/<triple>/` where
rextendr's Makevars does not look. Windows is skipped.

## Usage

``` r
conda_recipe(pkg = ".", dir = file.path(tempdir(), "conda"), .verbose = TRUE)
```

## Arguments

- pkg:

  String. Path to the package root. Defaults to `"."`.

- dir:

  String. Directory to write `recipe.yaml` into. Created if needed. Keep
  it outside `pkg`, the build copies `pkg` as its source. Defaults to a
  temporary directory.

- .verbose:

  Boolean. Report what was written. Defaults to `TRUE`.

## Value

The path of the recipe, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
recipe <- conda_recipe(".")
system2("rattler-build", c("build", "--recipe", recipe, "-c", "conda-forge"))
} # }
```
