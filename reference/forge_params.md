# Generate the parameter wrappers and their checkmate extensions

Reads every spec under `inst/params/`, writes the three generated files
under `R/` and formats them with air. The generated files are meant to
be committed.

## Usage

``` r
forge_params(pkg = ".", .verbose = TRUE)
```

## Arguments

- pkg:

  String. Path to the package root. Defaults to `"."`.

- .verbose:

  Boolean. Report what was written. Defaults to `TRUE`.

## Value

Character vector of the paths written, invisibly.
