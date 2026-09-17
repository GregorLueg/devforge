# Collect the specs defined in a package's spec directory

Sources every `.R` file under `inst/params/` in a fresh environment and
returns the `devforge_spec` objects it finds, in file then definition
order.

## Usage

``` r
load_specs(pkg = ".")
```

## Arguments

- pkg:

  String. Path to the package root. Defaults to `"."`.

## Value

A named list of `devforge_spec` objects, named by their `name`.
