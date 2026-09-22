# Merged sub-list field

For the constructors that take a list of overrides for a shared defaults
block, e.g. `knn = list(k = 25L)` on top of `params_knn_defaults()`. The
constructor merges the caller's list into the base with
`modifyList(keep.null = TRUE)` and splices the result flat into the
returned list at this field's position. When `from` names another spec,
the checker requires the spliced elements and validates them with that
spec's rules.

## Usage

``` r
p_merge(from, default = list(), overrides = NULL, doc = NULL)
```

## Arguments

- from:

  String or language object. The name of a spec in the same package
  (`"knn_defaults"` merges into `params_knn_defaults()`), or an
  expression evaluated inside the constructor, for a base that depends
  on the other arguments. A language `from` contributes nothing to the
  checker.

- default:

  List or language object. The formal default. Defaults to
  [`list()`](https://rdrr.io/r/base/list.html).

- overrides:

  List, language object or `NULL`. Constructor-specific defaults applied
  over `from` before the caller's list. A language object may reference
  the other formals, e.g.
  `quote(list(k = neighbours_within_batch * 2L))`. Defaults to `NULL`.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
