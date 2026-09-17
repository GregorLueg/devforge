# Check whether the generated files match the specs

Regenerates into a temporary directory and compares. Meant for CI, so
that a hand-edit of a generated file or a spec change that was never
regenerated fails the build.

## Usage

``` r
params_up_to_date(pkg = ".")
```

## Arguments

- pkg:

  String. Path to the package root. Defaults to `"."`.

## Value

`TRUE` when everything matches, otherwise a character vector of the
paths that are out of date.
