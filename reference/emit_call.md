# Lay out a call as source, one line if it fits

Lay out a call as source, one line if it fits

## Usage

``` r
emit_call(fn, args, budget = 72L)
```

## Arguments

- fn:

  String. The function name.

- args:

  Character vector or list of character vectors. One entry per argument.

- budget:

  Integer. Characters available on the single line. Defaults to `72L`.

## Value

Character vector of R source lines.
