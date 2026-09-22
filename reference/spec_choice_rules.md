# The choice rule table for a spec

The choice rule table for a spec

## Usage

``` r
spec_choice_rules(spec, specs = list())
```

## Arguments

- spec:

  A `devforge_spec`.

- specs:

  Named list of `devforge_spec` objects that merged fields may refer to.
  Defaults to an empty list.

## Value

Named list mapping field name to allowed values. Possibly empty.
