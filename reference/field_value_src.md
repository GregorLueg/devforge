# The source text of a field's value in a defaults block

A defaults block has no formals, so a choice field contributes the
resolved default rather than the whole set of choices.

## Usage

``` r
field_value_src(field)
```

## Arguments

- field:

  A `devforge_field`.

## Value

String. R source for the value.
