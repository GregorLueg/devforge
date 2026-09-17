# Integer field

Integer field

## Usage

``` r
p_int(
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  check_as = NULL,
  doc = NULL
)
```

## Arguments

- default:

  Integer or `NULL`. The default value.

- range:

  String or `NULL`. Checkmate range suffix, for example `"[1,)"`.

- null_ok:

  Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.

- len:

  Integer or string. `1L` for a scalar, `"+"` for one or more. Defaults
  to `1L`.

- check_as:

  Character vector or `NULL`. Overrides the checker's pattern, for a
  field the constructor resolves before returning it.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
