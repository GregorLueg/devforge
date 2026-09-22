# The returned list of a generated constructor

A plain [`list()`](https://rdrr.io/r/base/list.html) when nothing is
merged. Otherwise the plain fields are grouped into
[`list()`](https://rdrr.io/r/base/list.html) segments and joined with
the merged fields through [`c()`](https://rdrr.io/r/base/c.html), which
keeps the declared order.

## Usage

``` r
emit_return_list(spec)
```

## Arguments

- spec:

  A `devforge_spec`.

## Value

Character vector of R source lines.
