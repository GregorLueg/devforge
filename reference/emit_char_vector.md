# Lay out a character vector as source, one line if it fits

air preserves whatever line breaks it is given inside a call, so
anything that could overflow 80 characters has to be broken here rather
than left to the formatter.

## Usage

``` r
emit_char_vector(x, budget = 60L)
```

## Arguments

- x:

  Character vector.

- budget:

  Integer. Characters available on the single line. Defaults to `60L`.

## Value

Character vector of R source lines.
