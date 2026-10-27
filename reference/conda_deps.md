# Map R package dependencies to conda package specs

Base packages ship with `r-base` and are dropped. Bioconductor packages
are prefixed `bioconductor-`, everything else `r-`, both lowercased as
conda-forge and bioconda name them.

## Usage

``` r
conda_deps(deps, bioconductor)
```

## Arguments

- deps:

  List. Output of \[parse_dep_field()\].

- bioconductor:

  Character vector. Names of the Bioconductor packages.

## Value

Character vector of conda specs, e.g. `"r-duckdb >=1.5.5"`.
