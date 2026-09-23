# Source for a numeric default that survives the trip through roxygen

roxygen writes the Rd `\usage` by deparsing the default it parsed out of
the generated source, and `R CMD check`'s codoc then compares the two
renderings. For nearly every value
[`deparse()`](https://rdrr.io/r/base/deparse.html) is a fixed point and
the literal can stand as it is. It is not one for a value like `1e-300`,
where 15 significant digits are too few:
[`deparse()`](https://rdrr.io/r/base/deparse.html) gives
`9.99999999999999e-301`, deparsing that again gives
`9.99999998481683e-301`, and codoc reports a mismatch. There the literal
is wrapped in [`as.numeric()`](https://rdrr.io/r/base/numeric.html),
which keeps the exact value and leaves roxygen a call to print verbatim.

## Usage

``` r
stable_number_src(x, src)
```

## Arguments

- x:

  The default value.

- src:

  String. The literal
  [`deparse_value()`](https://gregorlueg.github.io/devforge/reference/deparse_value.md)
  produced for it.

## Value

String. R source for the right hand side of the formal.
