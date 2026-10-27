# Turn an R version string into a conda one

Conda versions cannot contain `-`, so `1.2-3` becomes `1.2_3`, the same
rewrite rattler-build's CRAN recipes use.

## Usage

``` r
conda_version(x)
```

## Arguments

- x:

  String. An R version, optionally with a comparison prefix.

## Value

String. The conda version.
