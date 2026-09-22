# Source for a string literal that fits the line width

Short strings come back as one literal. Longer ones are split on spaces
into a [`paste()`](https://rdrr.io/r/base/paste.html) call, the way the
packages already write their long messages by hand.

## Usage

``` r
emit_string(x, budget = 66L)
```

## Arguments

- x:

  String.

- budget:

  Integer. Maximum characters per chunk, quotes included. Defaults to
  `66L`.

## Value

Character vector of R source lines.
