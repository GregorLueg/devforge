# printing ---------------------------------------------------------------------

## format ----------------------------------------------------------------------

#' Format a field
#'
#' @description One line in Rust-ish notation: `int = 10L in [0,)`. A `?`
#' marks a nullable field, `(required)` one without a default.
#'
#' @param x A `devforge_field`.
#' @param ... Unused.
#'
#' @returns String.
#'
#' @keywords internal
#' @export
format.devforge_field <- function(x, ...) {
  type <- switch(
    x$type,
    choice = sprintf(
      "choice(%s)",
      paste0('"', x$choices, '"', collapse = ", ")
    ),
    enum = to_pascal_case(x$enum),
    merge = sprintf(
      "merge(%s)",
      if (is.character(x$from)) x$from else deparse_value(x$from)
    ),
    free = "any",
    x$type
  )
  if (x$null_ok) {
    type <- paste0(type, "?")
  }
  if (!identical(x$len, 1L) && !identical(x$len, 1)) {
    type <- sprintf("%s[%s]", type, x$len)
  }
  out <- if (x$required) {
    paste(type, "(required)")
  } else if (identical(x$type, "merge")) {
    type
  } else {
    paste(type, "=", field_value_src(x))
  }
  if (!is.null(x$range)) {
    out <- paste(out, "in", x$range)
  }
  out
}

#' Lay out named fields Rust style
#'
#' @description `head { a: int = 1L, b: lgl = TRUE }` when it fits in 80
#' characters, otherwise one field per line.
#'
#' @param head String. What goes before the brace.
#' @param fields Named list of `devforge_field` objects.
#' @param indent Integer. Indentation of the multi-line form. Defaults to `0L`.
#' @param trailer String. Appended after the closing brace. Defaults to `""`.
#'
#' @returns Character vector of lines.
#'
#' @keywords internal
format_braced <- function(head, fields, indent = 0L, trailer = "") {
  checkmate::qassert(head, "S1")
  checkmate::assertList(fields, types = "devforge_field")
  checkmate::qassert(indent, "I1[0,)")
  checkmate::qassert(trailer, "S1")
  pad <- strrep(" ", indent)
  if (length(fields) == 0L) {
    return(paste0(pad, head, trailer))
  }
  entries <- paste0(names(fields), ": ", purrr::map_chr(fields, format))
  one_line <- sprintf(
    "%s%s { %s }%s",
    pad,
    head,
    paste(entries, collapse = ", "),
    trailer
  )
  if (nchar(one_line) <= 80L) {
    return(one_line)
  }
  c(
    paste0(pad, head, " {"),
    paste0(pad, "  ", entries, ","),
    paste0(pad, "}", trailer)
  )
}

#' Format an enum spec
#'
#' @description Reads like the Rust declaration: `enum PcaSolver { ... }` with
#' each variant under its `///` doc line, plus the methods as an `impl` line.
#'
#' @param x A `devforge_enum`.
#' @param ... Unused.
#'
#' @returns Character vector of lines.
#'
#' @keywords internal
#' @export
format.devforge_enum <- function(x, ...) {
  variants <- purrr::imap(x$variants, \(v, name) {
    c(
      paste0("  /// ", v$doc),
      format_braced(to_pascal_case(name), v$fields, indent = 2L, trailer = ",")
    )
  })
  out <- c(
    sprintf("// %s: %s", x$name, x$title),
    sprintf("enum %s {", x$class),
    unlist(variants, use.names = FALSE),
    "}"
  )
  if (length(x$methods) > 0L) {
    out <- c(
      out,
      sprintf(
        "impl %s { %s }",
        x$class,
        paste0(names(x$methods), "()", collapse = ", ")
      )
    )
  }
  out
}

#' Format a variant spec
#'
#' @param x A `devforge_variant`.
#' @param ... Unused.
#'
#' @returns Character vector of lines.
#'
#' @keywords internal
#' @export
format.devforge_variant <- function(x, ...) {
  # A variant does not know its own name, the enum's names list holds it.
  c(paste0("/// ", x$doc), format_braced("Variant", x$fields))
}

#' Format a parameter spec
#'
#' @description The generated function, its checker and the fields with their
#' types, defaults and ranges.
#'
#' @param x A `devforge_spec`.
#' @param ... Unused.
#'
#' @returns Character vector of lines.
#'
#' @keywords internal
#' @export
format.devforge_spec <- function(x, ...) {
  kind <- if (x$defaults_only) "param_defaults" else "param_spec"
  head <- sprintf("params_%s()", x$name)
  if (!is.null(x$checker)) {
    head <- sprintf("%s -> check%sParams()", head, x$checker)
  }
  c(
    sprintf("// %s: %s", kind, x$title),
    format_braced(head, x$fields)
  )
}

## print -----------------------------------------------------------------------

#' Print a devforge object
#'
#' @description Prints the [format()] lines of a field, variant, enum or spec.
#'
#' @param x A `devforge_field`, `devforge_variant`, `devforge_enum` or
#' `devforge_spec`.
#' @param ... Passed on to [format()].
#'
#' @returns `x`, invisibly.
#'
#' @name print_devforge
NULL

#' Print the format() lines of an object
#'
#' @param x Any object with a [format()] method returning lines.
#' @param ... Passed on to [format()].
#'
#' @returns `x`, invisibly.
#'
#' @keywords internal
print_lines <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

#' @rdname print_devforge
#' @export
print.devforge_field <- print_lines

#' @rdname print_devforge
#' @export
print.devforge_variant <- print_lines

#' @rdname print_devforge
#' @export
print.devforge_enum <- print_lines

#' @rdname print_devforge
#' @export
print.devforge_spec <- print_lines
