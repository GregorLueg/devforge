# String field

String field

## Usage

``` r
p_chr(default, null_ok = FALSE, len = 1L, doc = NULL)
```

## Arguments

- default:

  String or `NULL`. The default value. Leave it out for a formal the
  caller must supply.

- null_ok:

  Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.

- len:

  Integer or string. `1L` for a scalar, `"+"` for one or more. Defaults
  to `1L`.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
