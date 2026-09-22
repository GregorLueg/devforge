# Numeric field

Numeric field

## Usage

``` r
p_dbl(
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  strict = FALSE,
  doc = NULL
)
```

## Arguments

- default:

  Numeric or `NULL`. The default value. Leave it out for a formal the
  caller must supply.

- range:

  String or `NULL`. Checkmate range suffix, for example `"(0, 1]"`.

- null_ok:

  Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.

- len:

  Integer or string. `1L` for a scalar, `"+"` for one or more. Defaults
  to `1L`.

- strict:

  Boolean. `TRUE` demands a double (`"R"`) rather than any number
  (`"N"`). Defaults to `FALSE`.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
