# The statement that merges a field into its base

`name <- utils::modifyList(base, name, keep.null = TRUE)`, with the
overrides layered between the base and the caller's list when there are
any.

## Usage

``` r
emit_merge(field, name)
```

## Arguments

- field:

  A `devforge_field` of type `"merge"`.

- name:

  String. The field name.

## Value

Character vector of R source lines.
