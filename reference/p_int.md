# Integer field

Integer field

## Usage

``` r
p_int(
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  integerish = FALSE,
  check_as = NULL,
  doc = NULL
)
```

## Arguments

- default:

  Integer or `NULL`. The default value. Leave it out for a formal the
  caller must supply.

- range:

  String or `NULL`. Checkmate range suffix, for example `"[1,)"`.

- null_ok:

  Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.

- len:

  Integer or string. `1L` for a scalar, `"+"` for one or more. Defaults
  to `1L`.

- integerish:

  Boolean. Accept whole doubles such as `1000` as well (`"X"` rather
  than `"I"`). Pair it with an
  [`as.integer()`](https://rdrr.io/r/base/integer.html) in `extra_ctor`
  when downstream code needs a real integer. Defaults to `FALSE`.

- check_as:

  Character vector or `NULL`. Overrides the checker's pattern, for a
  field the constructor resolves before returning it.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
