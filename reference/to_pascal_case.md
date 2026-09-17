# Convert a snake_case name into PascalCase

`ica_general` becomes `IcaGeneral`, which is how the checkmate
extensions are named. Consecutive digits stay attached to the token they
follow, so `node2vec` becomes `Node2vec`.

## Usage

``` r
to_pascal_case(x)
```

## Arguments

- x:

  String. A snake_case name.

## Value

String. The PascalCase equivalent.
