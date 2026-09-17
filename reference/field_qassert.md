# Derive the qassert pattern for a field

Folds type, length, range and nullability into the single pattern that
both the constructor's
[`checkmate::qassert()`](https://mllg.github.io/checkmate/reference/qassert.html)
call and the checker's rule table use. This is what settles the two
competing spellings of "integer or NULL" found across the packages onto
one.

## Usage

``` r
field_qassert(field, for_check = FALSE)
```

## Arguments

- field:

  A `devforge_field`.

- for_check:

  Boolean. Return the checker's pattern, which `check_as` may override,
  rather than the constructor's. Defaults to `FALSE`.

## Value

Character vector of qassert patterns, or `NULL` for a `"free"` field,
which carries no automatic validation.
