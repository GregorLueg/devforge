# The fields a spec's checker validates, merged fields expanded

A merged field that names another spec is replaced by that spec's own
checker fields, recursively. A merged field with a language `from`
contributes nothing. When a name turns up twice the first one wins,
matching what `$` finds on the list that
[`c()`](https://rdrr.io/r/base/c.html) builds.

## Usage

``` r
checker_fields(spec, specs = list())
```

## Arguments

- spec:

  A `devforge_spec`.

- specs:

  Named list of `devforge_spec` objects that merged fields may refer to.
  Defaults to an empty list.

## Value

Named list of `devforge_field` objects in return order.
