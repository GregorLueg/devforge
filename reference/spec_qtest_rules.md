# The qtest rule table for a spec

Choice fields are left out: `apply_choice_rules()` already implies a
string scalar, so a qtest entry would be redundant. Free fields carry no
pattern at all.

## Usage

``` r
spec_qtest_rules(spec, specs = list())
```

## Arguments

- spec:

  A `devforge_spec`.

- specs:

  Named list of `devforge_spec` objects that merged fields may refer to.
  Defaults to an empty list.

## Value

Named list mapping field name to qassert pattern. Possibly empty.
