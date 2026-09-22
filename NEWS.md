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