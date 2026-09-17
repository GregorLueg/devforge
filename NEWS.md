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