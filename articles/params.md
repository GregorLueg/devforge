# Generating parameter wrappers

## The problem

You like to reduce [parameter clutter for your
functions](https://design.tidyverse.org/argument-clutter.html) according
to tidy design principles? I do. A `params_xxx()` constructor that
returns a named list, a `checkXxxParams()` in a `checkmate_extensions.R`
file, and an `assertXxxParams()` built from it with
[`checkmate::makeAssertionFunction()`](https://mllg.github.io/checkmate/reference/makeAssertion.html).
However, this can be a pain in large packages with lots and lots of
these parameter wrappers.

Writing the same thing a hundred times has consequences: spelling
mistakes, inconsistent naming, documentation drift and staleness, etc.
You name it.

`devforge` takes a spec and writes both halves. It is a dev-time tool:
the generated files are committed, they are plain `checkmate` code, and
no package gains a runtime dependency on it.

``` r

library(devforge)
```

## A spec

A field carries a default, a type, an optional range, and its roxygen
prose.

``` r

spec <- param_spec(
  name = "kernel",
  title = "Wrapper function for the diffusion kernel parameters",
  checker = "Kernel",
  label = "kernel parameters",
  fields = list(
    sigma2 = p_dbl(1.0, doc = "Bandwidth parameter."),
    add_diag = p_dbl(1.0, doc = "Regularisation added to the diagonal."),
    a = p_dbl(3.0, doc = "Regularisation parameter for the `pstep` kernel."),
    p = p_int(5L, doc = "Number of steps for the `pstep` kernel.")
  ),
  extra_ctor = quote({
    checkmate::assertTRUE(a >= 2, .var.name = "a >= 2")
    checkmate::assertTRUE(p > 0L, .var.name = "p > 0")
  }),
  extra_check = quote({
    if (x$a < 2) {
      return("Parameter `a` must be >= 2 for the pstep kernel.")
    }
    if (x$p < 1L) {
      return("Parameter `p` must be a positive integer.")
    }
  })
)
```

That is the real `genewalkR::params_kernel()` spec, see
[here](https://gregorlueg.github.io/genewalkR/reference/params_kernel.html).
Note what is *not* in it: the qassert strings, the type annotations in
the roxygen, the documented defaults, the `must.include` name list, the
rule tables, and the assert sibling. All of those are derived, which is
exactly why they cannot drift.

The two `extra_*` slots are the escape hatch. Cross-field rules like
`a >= 2` cannot be expressed as a per-field pattern, so they go in
verbatim. The constructor asserts, the checker returns a string: that is
the only difference between the two, and both come from one place in the
spec.

## What comes out

``` r

cat(devforge:::emit_ctor(spec), sep = "\n")
#> #' Wrapper function for the diffusion kernel parameters
#> #'
#> #' @param sigma2 Numeric. Bandwidth parameter. Defaults to `1.0`.
#> #' @param add_diag Numeric. Regularisation added to the diagonal. Defaults to
#> #' `1.0`.
#> #' @param a Numeric. Regularisation parameter for the `pstep` kernel. Defaults
#> #' to `3.0`.
#> #' @param p Integer. Number of steps for the `pstep` kernel. Defaults to `5L`.
#> #'
#> #' @returns A named list with the following elements:
#> #' \itemize{
#> #'  \item sigma2 - Numeric. Bandwidth parameter. Defaults to `1.0`.
#> #'  \item add_diag - Numeric. Regularisation added to the diagonal. Defaults to
#> #'  `1.0`.
#> #'  \item a - Numeric. Regularisation parameter for the `pstep` kernel. Defaults
#> #'  to `3.0`.
#> #'  \item p - Integer. Number of steps for the `pstep` kernel. Defaults to `5L`.
#> #' }
#> #'
#> #' @export
#> params_kernel <- function(
#>   sigma2 = 1.0,
#>   add_diag = 1.0,
#>   a = 3.0,
#>   p = 5L
#> ) {
#>   # Checks
#>   checkmate::qassert(sigma2, "N1")
#>   checkmate::qassert(add_diag, "N1")
#>   checkmate::qassert(a, "N1")
#>   checkmate::qassert(p, "I1")
#> 
#>   checkmate::assertTRUE(a >= 2, .var.name = "a >= 2")
#>   checkmate::assertTRUE(p > 0L, .var.name = "p > 0")
#> 
#>   # Return
#>   list(
#>     sigma2 = sigma2,
#>     add_diag = add_diag,
#>     a = a,
#>     p = p
#>   )
#> }
```

The checker is three calls into a small set of shared helpers, which
`devforge` also emits so every package has them:

``` r

cat(devforge:::emit_checker(spec), sep = "\n")
#> #' Check kernel parameters
#> #'
#> #' @description Checkmate extension for the output of [params_kernel()].
#> #'
#> #' @param x The object to check.
#> #'
#> #' @returns `TRUE` if the check was successful, otherwise a
#> #' checkmate-style error string.
#> #'
#> #' @keywords internal
#> checkKernelParams <- function(x) {
#>   res <- check_list_shape(x, c("sigma2", "add_diag", "a", "p"))
#>   if (!isTRUE(res)) {
#>     return(res)
#>   }
#> 
#>   res <- apply_qtest_rules(
#>     x,
#>     list(
#>       sigma2 = "N1",
#>       add_diag = "N1",
#>       a = "N1",
#>       p = "I1"
#>     ),
#>     label = "kernel parameters"
#>   )
#>   if (!isTRUE(res)) {
#>     return(res)
#>   }
#> 
#>   if (x$a < 2) {
#>     return("Parameter `a` must be >= 2 for the pstep kernel.")
#>   }
#>   if (x$p < 1L) {
#>     return("Parameter `p` must be a positive integer.")
#>   }
#> 
#>   return(TRUE)
#> }
#> 
#> #' Assert kernel parameters
#> #'
#> #' @inheritParams checkKernelParams
#> #' @param .var.name Name of the checked object to print in assertions.
#> #' @param add Collection to store assertion messages. See
#> #' [checkmate::makeAssertCollection()].
#> #'
#> #' @returns Invisibly returns the checked object if the assertion is
#> #' successful.
#> #'
#> #' @keywords internal
#> assertKernelParams <- checkmate::makeAssertionFunction(checkKernelParams)
```

## Field types

[`p_int()`](https://gregorlueg.github.io/devforge/reference/p_int.md),
[`p_dbl()`](https://gregorlueg.github.io/devforge/reference/p_dbl.md),
[`p_lgl()`](https://gregorlueg.github.io/devforge/reference/p_lgl.md),
[`p_chr()`](https://gregorlueg.github.io/devforge/reference/p_chr.md),
[`p_choice()`](https://gregorlueg.github.io/devforge/reference/p_choice.md)
and
[`p_free()`](https://gregorlueg.github.io/devforge/reference/p_free.md).
Range and nullability fold into one qassert pattern, which settles the
two competing spellings on one:

``` r

devforge:::field_qassert(p_int(200L, range = "[1,)"))
#> [1] "I1[1,)"
devforge:::field_qassert(p_int(NULL, range = "[1,)", null_ok = TRUE))
#> [1] "I1[1,)" "0"
devforge:::field_qassert(p_int(NULL, len = "+", null_ok = TRUE))
#> [1] "I+" "0"
devforge:::field_qassert(p_dbl(1.0, range = "[1, 2]", strict = TRUE))
#> [1] "R1[1, 2]"
```

A choice field emits
[`match.arg()`](https://rdrr.io/r/base/match.arg.html) plus
[`checkmate::assertChoice()`](https://mllg.github.io/checkmate/reference/checkChoice.html)
in the constructor and an `apply_choice_rules()` entry in the checker,
and moves the default to the front of the set so
[`match.arg()`](https://rdrr.io/r/base/match.arg.html) picks it:

``` r

p_choice("kmknn", c("hnsw", "kmknn", "annoy"))$choices
#> [1] "kmknn" "hnsw"  "annoy"
```

[`p_free()`](https://gregorlueg.github.io/devforge/reference/p_free.md)
is the hatch for anything a pattern cannot express. It contributes a
formal, a default and its roxygen, and nothing else. Pair it with an
`extra_check`.

Leave the default out and the formal becomes required. The roxygen says
`Required.` instead of `Defaults to`, and the constructor fails the way
any R function does when the caller forgets it. `integerish = TRUE`
swaps the `"I"` for an `"X"`, for the `n_epochs = 1000` a user types
without the `L`:

``` r

devforge:::field_qassert(p_int(range = "[1,)", integerish = TRUE))
#> [1] "X1[1,)"
p_int(range = "[1,)")$required
#> [1] TRUE
```

## Merging a shared defaults block

Half the constructors in a single cell package take the same kNN block.
A
[`param_defaults()`](https://gregorlueg.github.io/devforge/reference/param_defaults.md)
spec holds it once:

``` r

knn <- param_defaults(
  name = "knn_defaults",
  title = "Default parameters for the kNN search",
  checker = "Knn",
  label = "kNN parameters",
  fields = list(
    k = p_int(15L, range = "[1,)", doc = "Number of neighbours."),
    metric = p_choice(
      "euclidean",
      c("euclidean", "cosine"),
      doc = "Distance metric."
    )
  )
)
```

A
[`p_merge()`](https://gregorlueg.github.io/devforge/reference/p_merge.md)
field on another spec takes the caller’s overrides as a list. The
constructor layers them over `params_knn_defaults()`, then over any
constructor-specific `overrides`, and splices the result flat into the
returned list at the field’s position:

``` r

spec_umap <- param_spec(
  name = "umap",
  title = "Wrapper function for the UMAP parameters",
  checker = "Umap",
  label = "UMAP parameters",
  fields = list(
    n_epochs = p_int(range = "[1,)", integerish = TRUE, doc = "Epochs."),
    min_dist = p_dbl(0.1, range = "(0,1]", doc = "Minimum distance."),
    knn = p_merge(
      "knn_defaults",
      overrides = list(k = 30L),
      doc = "Overrides for the kNN search."
    )
  )
)
cat(devforge:::emit_ctor(spec_umap), sep = "\n")
#> #' Wrapper function for the UMAP parameters
#> #'
#> #' @param n_epochs Integer. Epochs. Required.
#> #' @param min_dist Numeric. Minimum distance. Defaults to `0.1`.
#> #' @param knn List. Overrides for the kNN search. See [params_knn_defaults()]
#> #' for the available elements. Defaults to `list()`.
#> #'
#> #' @returns A named list with the following elements:
#> #' \itemize{
#> #'  \item n_epochs - Integer. Epochs. Required.
#> #'  \item min_dist - Numeric. Minimum distance. Defaults to `0.1`.
#> #'  \item The elements of [params_knn_defaults()], overridden by `knn`, spliced
#> #'  in at this position.
#> #' }
#> #'
#> #' @export
#> params_umap <- function(
#>   n_epochs,
#>   min_dist = 0.1,
#>   knn = list()
#> ) {
#>   # Checks
#>   checkmate::qassert(n_epochs, "X1[1,)")
#>   checkmate::qassert(min_dist, "N1(0,1]")
#> 
#>   # Merge
#>   knn <- utils::modifyList(params_knn_defaults(),
#>     utils::modifyList(list(k = 30L), knn,
#>       keep.null = TRUE), keep.null = TRUE)
#> 
#>   # Return
#>   c(
#>     list(
#>       n_epochs = n_epochs,
#>       min_dist = min_dist
#>     ),
#>     knn
#>   )
#> }
```

The checker follows the merge. `checkUmapParams()` requires `k` and
`metric` alongside the two plain fields and validates them with the
rules of the `knn_defaults` spec, so nobody writes a second rule table
for the same block:

``` r

cat(devforge:::emit_checker(spec_umap, list(knn_defaults = knn)), sep = "\n")
#> #' Check UMAP parameters
#> #'
#> #' @description Checkmate extension for the output of [params_umap()].
#> #'
#> #' @param x The object to check.
#> #'
#> #' @returns `TRUE` if the check was successful, otherwise a
#> #' checkmate-style error string.
#> #'
#> #' @keywords internal
#> checkUmapParams <- function(x) {
#>   res <- check_list_shape(x, c("n_epochs", "min_dist", "k", "metric"))
#>   if (!isTRUE(res)) {
#>     return(res)
#>   }
#> 
#>   res <- apply_qtest_rules(
#>     x,
#>     list(
#>       n_epochs = "X1[1,)",
#>       min_dist = "N1(0,1]",
#>       k = "I1[1,)"
#>     ),
#>     label = "UMAP parameters"
#>   )
#>   if (!isTRUE(res)) {
#>     return(res)
#>   }
#> 
#>   res <- apply_choice_rules(
#>     x,
#>     list(
#>       metric = c("euclidean", "cosine")
#>     ),
#>     label = "UMAP parameters"
#>   )
#>   if (!isTRUE(res)) {
#>     return(res)
#>   }
#> 
#>   return(TRUE)
#> }
#> 
#> #' Assert UMAP parameters
#> #'
#> #' @inheritParams checkUmapParams
#> #' @param .var.name Name of the checked object to print in assertions.
#> #' @param add Collection to store assertion messages. See
#> #' [checkmate::makeAssertCollection()].
#> #'
#> #' @returns Invisibly returns the checked object if the assertion is
#> #' successful.
#> #'
#> #' @keywords internal
#> assertUmapParams <- checkmate::makeAssertionFunction(checkUmapParams)
```

`from` and `overrides` can also be language objects. They are evaluated
inside the constructor and may reference the other formals, for a base
that depends on `neighbours_within_batch` say. A language `from`
contributes nothing to the checker, since there is no spec to take rules
from.

## Running it

Specs live in `inst/params/*.R`. They ship, so one package can reference
another’s rather than reaching in with `:::`.

``` r

devforge::forge_params(".")
```

That writes three files under `R/`, each headed
`# Generated by devforge. Do not edit.`, and runs `air` over them:

- `R/params-generated.R`, the constructors
- `R/checkmate-params-generated.R`, the checkers and their assert
  siblings
- `R/params-prelude-generated.R`, the three shared helpers

The hand-written checkers that validate something other than a params
list stay where they are. `checkGeneWalkGraphDt()` checks a
`data.table`, and that is not this tool’s job.

For CI there is a drift guard that regenerates into a temporary
directory and compares:

``` r

devforge::params_up_to_date(".")
```

`TRUE` when everything matches, otherwise the paths that are stale. That
catches both a hand-edit of a generated file and a spec change that was
never regenerated.

Don’t want to write the GitHub Actions workflow yourself? This drops one
into `.github/workflows/params-drift.yml`:

``` r

devforge::use_drift_ci(".")
```

The runner defaults to macOS. Pick the platform you forge the specs on:
macOS arm64 R has no extended long double, so a literal like `1e-300`
deparses differently than on Linux and every generated file reads as
stale. Forging on Linux? Pass `runner = "ubuntu-latest"`.

## What is next

Three linters, each aimed at something the survey of the five packages
turned up rather than at a hypothetical: roxygen that has drifted away
from the formals it documents, function inputs that never reach a
`checkmate` call, and `rs_*` bindings without an R wrapper. Watch this
space.
