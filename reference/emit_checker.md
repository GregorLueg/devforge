# A generated `check*Params()` and its assertion sibling

A generated `check*Params()` and its assertion sibling

## Usage

``` r
emit_checker(spec, specs = list())
```

## Arguments

- spec:

  A `devforge_spec`.

- specs:

  Named list of `devforge_spec` objects that merged fields may refer to.
  Defaults to an empty list.

## Value

Character vector of R source lines, or an empty vector when the spec
declares no checker.
