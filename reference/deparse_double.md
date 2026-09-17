# Deparse a numeric default keeping its decimal point

`deparse(1.0)` gives `"1"`, which reads as an integer in the generated
source. Whole numbers written as doubles keep a `.0` so the generated
formals look like the hand-written ones.

## Usage

``` r
deparse_double(x)
```

## Arguments

- x:

  Numeric or `NULL`.

## Value

String. R source for the value.
