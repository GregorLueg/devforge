# utils ------------------------------------------------------------------------

#' Null coalescing operator
#'
#' @param lhs Any object. Returned unless it is `NULL`.
#' @param rhs Any object. Returned when `lhs` is `NULL`.
#'
#' @returns `lhs` unless it is `NULL`, otherwise `rhs`.
#'
#' @noRd
`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs

#' Deparse a value into source code
#'
#' @description Turns an R value back into the source text that recreates it.
#' Used to write defaults and rule tables into the generated files. Integers
#' keep their `L` suffix, strings keep their quotes, `NULL` stays `NULL`.
#'
#' @param x Any R object that can be deparsed.
#'
#' @returns String. A single line of R source.
#'
#' @keywords internal
deparse_value <- function(x) {
  paste(deparse(x, width.cutoff = 500L), collapse = " ")
}

#' Convert a snake_case name into PascalCase
#'
#' @description `ica_general` becomes `IcaGeneral`, which is how the checkmate
#' extensions are named. Consecutive digits stay attached to the token they
#' follow, so `node2vec` becomes `Node2vec`.
#'
#' @param x String. A snake_case name.
#'
#' @returns String. The PascalCase equivalent.
#'
#' @keywords internal
to_pascal_case <- function(x) {
  checkmate::qassert(x, "S1")
  parts <- strsplit(x, "_", fixed = TRUE)[[1]]
  parts <- parts[nzchar(parts)]
  paste0(toupper(substring(parts, 1L, 1L)), substring(parts, 2L), collapse = "")
}

#' Indent a block of source code
#'
#' @param lines Character vector. The lines to indent.
#' @param n Integer. Number of spaces. Defaults to `2L`.
#'
#' @returns Character vector with each non-empty line indented.
#'
#' @keywords internal
indent <- function(lines, n = 2L) {
  checkmate::qassert(lines, "S*")
  checkmate::qassert(n, "I1[0,)")
  pad <- strrep(" ", n)
  ifelse(nzchar(lines), paste0(pad, lines), lines)
}

#' Wrap roxygen prose to the 80 character line width
#'
#' @description The house style caps lines at 80 characters. Roxygen
#' continuation lines carry no extra indent, matching what is written by hand.
#'
#' @param text String. The prose to wrap.
#' @param prefix String. What goes in front of the first line, for example
#' `"#' @param maxit "`.
#' @param cont String. What goes in front of every continuation line. Defaults
#' to `"#' "`.
#'
#' @returns Character vector of roxygen lines.
#'
#' @keywords internal
wrap_roxygen <- function(text, prefix, cont = "#' ") {
  checkmate::qassert(text, "S1")
  checkmate::qassert(prefix, "S1")
  checkmate::qassert(cont, "S1")
  words <- strsplit(trimws(text), "\\s+")[[1]]
  lines <- character(0)
  current <- prefix
  for (word in words) {
    candidate <- if (identical(current, prefix)) {
      paste0(current, word)
    } else {
      paste(current, word)
    }
    if (nchar(candidate) > 80L && !identical(current, prefix)) {
      lines <- c(lines, current)
      current <- paste0(cont, word)
    } else {
      current <- candidate
    }
  }
  c(lines, current)
}

#' Deparse a numeric default keeping its decimal point
#'
#' @description `deparse(1.0)` gives `"1"`, which reads as an integer in the
#' generated source. Whole numbers written as doubles keep a `.0` so the
#' generated formals look like the hand-written ones.
#'
#' @param x Numeric or `NULL`.
#'
#' @returns String. R source for the value.
#'
#' @keywords internal
deparse_double <- function(x) {
  whole <- is.numeric(x) &&
    length(x) > 0L &&
    all(is.finite(x)) &&
    all(x == round(x)) &&
    all(abs(x) < 1e15)
  if (!whole) {
    return(deparse_value(x))
  }
  src <- paste0(format(x, trim = TRUE, scientific = FALSE), ".0")
  if (length(src) == 1L) src else paste0("c(", paste(src, collapse = ", "), ")")
}
