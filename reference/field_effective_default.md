# The documented default of a field

For a choice field the formal default is the whole set of choices, but
what is documented is the first one, which is what
[`match.arg()`](https://rdrr.io/r/base/match.arg.html) picks.

## Usage

``` r
field_effective_default(field)
```

## Arguments

- field:

  A `devforge_field`.

## Value

The value that the field takes when the caller passes nothing.
