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

## What is next

Three linters, each aimed at something the survey of the five packages
turned up rather than at a hypothetical: roxygen that has drifted away
from the formals it documents, function inputs that never reach a
`checkmate` call, and `rs_*` bindings without an R wrapper. Watch this
space.
