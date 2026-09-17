# devforge

<!-- badges: start -->
[![R-CMD-check](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml/badge.svg)](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml)
<!-- badges: end -->

Development tooling for the bixverse family of R packages. Dev-time only: it is
never an `Imports:` of anything it generates.

## What it does

Takes a declarative spec and writes both halves of the parameter wrapper
pattern: the `params_xxx()` constructor and its paired `checkXxxParams()` /
`assertXxxParams()` checkmate extension, with full roxygen. The generated files
are committed and are plain `checkmate` code.

Across the five packages that pattern runs to 103 constructors, 96 check/assert
pairs and about 13,700 lines, most of it a default, a qassert string and a
roxygen line written by hand. Writing it a hundred times is how you end up with
two spellings of "integer or `NULL`", four different checker naming conventions,
and roxygen that quotes defaults the constructor stopped using.

```r
spec_kernel <- param_spec(
  name = "kernel",
  title = "Wrapper function for the diffusion kernel parameters",
  fields = list(
    sigma2 = p_dbl(1.0, doc = "Bandwidth parameter."),
    p = p_int(5L, range = "[1,)", doc = "Number of steps for the kernel.")
  )
)
```

Specs live in `inst/params/*.R`. Then:

```r
devforge::forge_params(".")      # writes R/*-generated.R and runs air
devforge::params_up_to_date(".") # the CI drift guard
```

See `vignette("params")` for the escape hatches and the migration recipe.

## Installation

```r
install.packages(
  "devforge",
  repos = c("https://gregorlueg.r-universe.dev", "https://cloud.r-project.org")
)
```
