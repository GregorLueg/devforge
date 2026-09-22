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

Shared defaults blocks are merged rather than repeated. A `p_merge()` field
takes the caller's overrides, layers them over `params_knn_defaults()` and
splices the result flat into the returned list. The checker picks up the
spliced elements and their rules from the base spec:

```r
spec_umap <- param_spec(
  name = "umap",
  title = "Wrapper function for the UMAP parameters",
  checker = "Umap",
  fields = list(
    n_epochs = p_int(range = "[1,)", integerish = TRUE, doc = "Epochs."),
    knn = p_merge("knn_defaults", doc = "Overrides for the kNN search.")
  )
)
```

Leave the default out of a field and the formal is required. `integerish`
accepts the `1000` a user types without the `L`.

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

