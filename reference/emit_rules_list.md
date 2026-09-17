# Source text for a named list of rules

Source text for a named list of rules

## Usage

``` r
emit_rules_list(rules, trailing_comma = FALSE)
```

## Arguments

- rules:

  Named list of character vectors.

- trailing_comma:

  Boolean. Append a comma to the closing paren, for when the list is one
  argument among several. Defaults to `FALSE`.

## Value

Character vector of R source lines, the opening `list(` included.
