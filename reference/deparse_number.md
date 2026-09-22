# The shortest literal that reads back as the same double

[`deparse()`](https://rdrr.io/r/base/deparse.html) stops at 15
significant digits, which turns `1e-300` into `9.99999999999999e-301`
and `1/3` into a different double.

## Usage

``` r
deparse_number(x)
```

## Arguments

- x:

  A double scalar.

## Value

String.
