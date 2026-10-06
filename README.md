# devforge <img src="man/figures/logo.png" align="right" height="138" alt="devforge logo" />

[![r_package](https://img.shields.io/github/r-package/v/GregorLueg/devforge?label=R_package&color=orange)](https://github.com/GregorLueg/devforge/blob/main/DESCRIPTION)
[![devforge status badge](https://gregorlueg.r-universe.dev/devforge/badges/version)](https://gregorlueg.r-universe.dev/devforge)
[![CI](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml/badge.svg)](https://github.com/GregorLueg/devforge/actions/workflows/R-cmd-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pkgdown](https://img.shields.io/badge/pkgdown-website-1b5e9f?logo=github)](https://gregorlueg.github.io/devforge/)

Development tooling for R packages, built for the bixverse family but not tied
to it. Dev-time only: it is never an `Imports:` of anything it generates.

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

**Second feature:**

Rust style enums. Strings are R's enums, and they fall apart the moment one
variant needs fields the others do not: `momentum` for SGD, `beta1` and `beta2`
for Adam, all flat in one list and silently ignored for the wrong optimiser. A
`param_enum()` gives every variant its own fields:

```r
enum_optimiser <- param_enum(
  name = "optimiser",
  title = "optimiser",
  variants = list(
    sgd = p_variant(
      "Stochastic gradient descent.",
      momentum = p_dbl(0.9, range = "[0,1)", doc = "Momentum.")
    ),
    adam = p_variant(
      "Adam.",
      beta1 = p_dbl(0.9, range = "[0,1)", doc = "First moment decay."),
      beta2 = p_dbl(0.999, range = "[0,1)", doc = "Second moment decay.")
    ),
    lbfgs = p_variant(
      "Limited memory BFGS.",
      history = p_int(10L, range = "[1,)", doc = "Stored updates.")
    )
  ),
  methods = list(step = "Take one optimisation step")
)
```

Out come a validated constructor per variant (`optimiser_adam()`), a coercion
from the variant name (`as_optimiser("sgd")`), a checker that rejects fields
belonging to another variant, and an exhaustive match. Leave an arm out and it
errors on every call, not just when the missing variant shows up:

```r
match_optimiser(
  optimiser_adam(beta1 = 0.95),
  sgd = \(v) v$momentum,
  adam = \(v) c(v$beta1, v$beta2),
  lbfgs = \(v) v$history
)
#> [1] 0.950 0.999
```

`methods` are the impl blocks: one S3 generic each, with the bodies written by
hand in `R/` per variant or once for the whole enum. `forge_params()` errors
when a variant has neither, which is as close to `rustc` complaining about a
non-exhaustive match as R gets. Payloads can be anything: required fields,
`p_free()` for a matrix, or another enum. Inside a `param_spec()`, a
`p_enum("optimiser", "adam")` field still takes the plain string from the
caller and hands back the full variant.

See `vignette("enums")` for the details.

## Installation

Simplest is to install from R-universe:

```r
install.packages(
  "devforge",
  repos = c("https://gregorlueg.r-universe.dev", "https://cloud.r-project.org")
)
```

