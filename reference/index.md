# Package index

## Specs

The declarative description of a parameter wrapper

- [`param_spec()`](https://gregorlueg.github.io/devforge/reference/param_spec.md)
  : Parameter wrapper specification
- [`param_defaults()`](https://gregorlueg.github.io/devforge/reference/param_defaults.md)
  : Defaults block specification
- [`load_specs()`](https://gregorlueg.github.io/devforge/reference/load_specs.md)
  : Collect the specs defined in a package's spec directory

## Field types

One constructor per kind of parameter

- [`p_int()`](https://gregorlueg.github.io/devforge/reference/p_int.md)
  : Integer field
- [`p_dbl()`](https://gregorlueg.github.io/devforge/reference/p_dbl.md)
  : Numeric field
- [`p_lgl()`](https://gregorlueg.github.io/devforge/reference/p_lgl.md)
  : Boolean field
- [`p_chr()`](https://gregorlueg.github.io/devforge/reference/p_chr.md)
  : String field
- [`p_choice()`](https://gregorlueg.github.io/devforge/reference/p_choice.md)
  : Choice field
- [`p_free()`](https://gregorlueg.github.io/devforge/reference/p_free.md)
  : Unvalidated field

## Generation

Writing the generated files and keeping them honest

- [`forge_params()`](https://gregorlueg.github.io/devforge/reference/forge_params.md)
  : Generate the parameter wrappers and their checkmate extensions
- [`params_up_to_date()`](https://gregorlueg.github.io/devforge/reference/params_up_to_date.md)
  : Check whether the generated files match the specs
