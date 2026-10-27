# Split a DESCRIPTION dependency field into names and constraints

Split a DESCRIPTION dependency field into names and constraints

## Usage

``` r
parse_dep_field(x)
```

## Arguments

- x:

  String or `NULL`. The raw field, e.g. `"a, b (>= 1.0)"`.

## Value

A list with:

- name - Character vector. Package names.

- constraint - Character vector. Conda version constraints such as
  `">=1.0"`, empty where the field gives none.
