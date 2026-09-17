# devforge <img src="man/figures/logo.png" align="right" height="138" alt="devforge logo" />

[![r_package](https://img.shields.io/github/r-package/v/GregorLueg/devforge?label=R_package&color=orange)](https://github.com/GregorLueg/devforge/blob/main/DESCRIPTION)
[![devforge status badge](https://gregorlueg.r-universe.dev/devforge/badges/version)](https://gregorlueg.r-universe.dev/devforge)
[![CI](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml/badge.svg)](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pkgdown](https://img.shields.io/badge/pkgdown-website-1b5e9f?logo=github)](https://gregorlueg.github.io/devforge/)

Development tooling for the bixverse family of R packages + others.  Dev-time 
only: it is never an `Imports:` of anything it generates.

## What it does

**First feature:**

Takes a declarative spec and writes both halves of the parameter wrapper
pattern: the `params_xxx()` constructor and its paired `checkXxxParams()` /
`assertXxxParams()` checkmate extension, with full roxygen. The generated files
are committed and are plain `checkmate` code.

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

Simplest is to install from R-universe:

```r
install.packages(
  "devforge",
  repos = c("https://gregorlueg.r-universe.dev", "https://cloud.r-project.org")
)
```

