# devforge 0.1.0

## Features

- A first implementation of a Rust-inspired `Enum` for R. `param_enum()`
  declares the variants, `p_variant()` gives each one its own fields. Every
  enum gets a validated constructor per variant (`<enum>_<variant>()`),
  `as_<enum>()` to build a variant from its name or restore a list's class, a
  `check<Enum>()` / `assert<Enum>()` pair that rejects fields belonging to
  another variant, and an exhaustive `match_<enum>()` that errors on a missing
  arm whatever value it is called with. `.default` is the `_ =>` arm.
- Impl blocks. `param_enum(methods = ...)` emits one S3 generic per method.
  The methods are written by hand in `R/`, per variant class or once for the
  enum class. `forge_params()` and `params_up_to_date()` parse `R/` and error
  when a variant has neither.
- Variant payloads take any field type but `p_merge()`: required fields,
  `p_free()` for a matrix or a `data.table`, and `p_enum()` for nested enums,
  which are checked with their own checker.
- `p_enum()` puts an enum into a `param_spec()`. The formal still takes the
  variant name as a string, the constructor hands back the full variant, and
  the params checker delegates to the enum's checker. `param_defaults()`
  rejects enum fields for now, since `modifyList()` would merge the fields of
  two different variants.
- Every enum gets `format()` and `print()` methods in Rust `{:?}` style:
  `PcaSolver::Randomised { oversample: 10, n_iter: 2 }` on one line when it
  fits, one field per line when it does not. Matrices and data frames print as
  `<matrix 500 x 30>`, long vectors as `<double[1000]>`, nested enums inline.
- Enums go into their own `R/enums-generated.R` with a self-contained helper,
  so a package with enums and no params specs gets just that one file. The
  params prelude is unchanged for packages without enums.
- `forge_params()` removes a generated file once the last spec feeding it is
  gone, and `params_up_to_date()` reports it as stale until then.
- New `vignette("enums")`.

## Other

- The roxygen label examples in the emitted prelude no longer mention
  bixverse params. Every consumer's `R/params-prelude-generated.R` reads as
  stale once, until `forge_params()` is run again.
- Title, docs and the params vignette use package agnostic examples. devforge
  is built for the bixverse family but works for any R package.

# devforge 0.0.6

## Features

- `use_drift_ci()` drops the params drift workflow into `.github/workflows/`,
  so a package using devforge specs fails CI when the generated files go stale.

# devforge 0.0.5

## Bug fixes

- Numeric defaults that R's own deparse() renders differently are emitted as 
  `as.numeric("<literal>")`. roxygen deparses the default into the Rd `\usage`, 
  and `deparse()` is not always a fixed point (`1e-300` becomes 
  `9.99999999999999e-301`), so codoc flagged a mismatch. 
- details lines that already fit the width are left as written. 0.0.4 reflowed 
  every line and stripped the indentation from hand-written `\itemize{}` blocks.

# devforge 0.0.4

## Features

* `p_merge()`, a field that takes a list of overrides for a shared defaults
  block. The constructor merges the caller's list into the base with
  `modifyList(keep.null = TRUE)` and splices the result flat into the returned
  list at the field's position. When `from` names another spec, the checker
  requires the spliced elements and validates them with that spec's rules, so
  `params_umap()` can carry the kNN defaults without a second checker. A
  language `from` or `overrides` is evaluated inside the constructor and may
  reference the other formals.
* Required formals. Leave the default out of `p_int()`, `p_dbl()`, `p_lgl()`,
  `p_chr()` or `p_free()` and the formal is emitted without one. The roxygen
  says `Required.` instead of `Defaults to`.
* `p_int(integerish = TRUE)` asserts with `"X"` rather than `"I"`, for the
  arguments that arrive as `1000` from a user who did not type the `L`.
* `param_defaults()` takes `details` and `references` like `param_spec()`.

## Bug fixes

* Doubles are deparsed to the shortest literal that reads back as the same
  value. `deparse()` stops at 15 significant digits, which turned `1e-300`
  into `9.99999999999999e-301` and `1/3` into a different double.
* Long `label` and `hint` strings on a checker are split into a `paste()` call
  instead of overflowing the width.
* `details` lines over the width are wrapped. Line breaks are still kept, so a
  hand-written `\itemize{}` survives.

# devforge 0.0.3

## Features

* Added the option to have references for the parameter wrappers.

# devforge 0.0.2

## Bug fixes

* A spec with a `hint` emitted the argument separator on a line of its own,
  giving `label = "x"`, then a bare `,`, then `hint = "y"`. Valid R, but it
  ships to the consumer and `air` will not join it back when that package sets
  `persistent-line-breaks`. The comma now goes on the end of the label line.
  The tinytest specs never set `hint`, which is why this got out.
* `extra_ctor` and `extra_check` blocks could exceed the 80 character width.
  `width.cutoff` is a hint to `deparse()` rather than a limit, so the default
  of 60 happily returned a 95 character line. Statements that come out too wide
  are now re-deparsed at a tighter cutoff, and the trailing space that leaves
  on each broken line is stripped.
* `forge_params()` now warns, with file and line, about any generated line that
  still exceeds the width. An unbreakable string literal cannot be reflowed by
  anyone, so the spec is where it has to be shortened.

## Other

* `assertXxxParams()` and `testXxxParams()` are emitted with roxygen. Only the
  checker had any, so `roxygen2` wrote an `.Rd` for `checkXxxParams()` and
  deleted the one for its assert sibling.

# devforge 0.0.1

First beta release of this package.