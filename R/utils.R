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
  if (is.double(x) && is.null(attributes(x)) && length(x) > 0L) {
    src <- purrr::map_chr(x, deparse_number)
    return(if (length(src) == 1L) src else sprintf("c(%s)", toString(src)))
  }
  src <- paste(deparse(x, width.cutoff = 500L), collapse = " ")
  if (!is.language(x) && !identical(eval(str2lang(src), baseenv()), x)) {
    src <- paste(
      deparse(
        x,
        width.cutoff = 500L,
        control = c(
          "keepNA",
          "keepInteger",
          "niceNames",
          "showAttributes",
          "digits17"
        )
      ),
      collapse = " "
    )
  }
  src
}

#' Source for a numeric default that survives the trip through roxygen
#'
#' @description roxygen writes the Rd `\usage` by deparsing the default it
#' parsed out of the generated source, and `R CMD check`'s codoc then compares
#' the two renderings. For nearly every value `deparse()` is a fixed point and
#' the literal can stand as it is. It is not one for a value like `1e-300`,
#' where 15 significant digits are too few: `deparse()` gives
#' `9.99999999999999e-301`, deparsing that again gives
#' `9.99999998481683e-301`, and codoc reports a mismatch. There the literal is
#' wrapped in `as.numeric()`, which keeps the exact value and leaves roxygen a
#' call to print verbatim.
#'
#' @param x The default value.
#' @param src String. The literal [deparse_value()] produced for it.
#'
#' @returns String. R source for the right hand side of the formal.
#'
#' @keywords internal
stable_number_src <- function(x, src) {
  checkmate::qassert(src, "S1")
  if (!is.double(x) || length(x) != 1L || !is.finite(x)) {
    return(src)
  }
  own <- deparse(x)
  if (identical(deparse(as.numeric(own)), own)) {
    return(src)
  }
  sprintf("as.numeric(%s)", deparse_value(deparse_number(x)))
}

#' The shortest literal that reads back as the same double
#'
#' @description `deparse()` stops at 15 significant digits, which turns
#' `1e-300` into `9.99999999999999e-301` and `1/3` into a different double.
#'
#' @param x A double scalar.
#'
#' @returns String.
#'
#' @keywords internal
deparse_number <- function(x) {
  src <- deparse(x)
  if (!is.finite(x) || identical(as.numeric(src), x)) {
    return(src)
  }
  for (digits in 1:17) {
    src <- trimws(formatC(x, digits = digits, format = "g"))
    if (identical(as.numeric(src), x)) {
      break
    }
  }
  src
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

#' Lay out a character vector as source, one line if it fits
#'
#' @description air preserves whatever line breaks it is given inside a call,
#' so anything that could overflow 80 characters has to be broken here rather
#' than left to the formatter.
#'
#' @param x Character vector.
#' @param budget Integer. Characters available on the single line. Defaults to
#' `60L`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_char_vector <- function(x, budget = 60L) {
  checkmate::qassert(x, "S+")
  checkmate::qassert(budget, "I1[1,)")
  one_line <- deparse_value(x)
  if (nchar(one_line) <= budget) {
    return(one_line)
  }
  c(
    "c(",
    indent(paste0(
      sprintf('"%s"', x),
      c(rep(",", length(x) - 1L), "")
    )),
    ")"
  )
}

#' Lay out a call as source, one line if it fits
#'
#' @param fn String. The function name.
#' @param args Character vector or list of character vectors. One entry per
#' argument.
#' @param budget Integer. Characters available on the single line. Defaults to
#' `72L`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_call <- function(fn, args, budget = 72L) {
  checkmate::qassert(fn, "S1")
  checkmate::qassert(budget, "I1[1,)")
  args <- purrr::map(args, \(a) if (is.character(a)) a else as.character(a))
  flat <- purrr::map_chr(args, \(a) paste(a, collapse = " "))
  one_line <- sprintf("%s(%s)", fn, paste(flat, collapse = ", "))
  fits <- nchar(one_line) <= budget &&
    all(purrr::map_int(args, length) == 1L)
  if (fits) {
    return(one_line)
  }
  body <- purrr::imap(args, \(a, i) {
    if (i < length(args)) {
      c(utils::head(a, -1L), paste0(utils::tail(a, 1L), ","))
    } else {
      a
    }
  })
  c(paste0(fn, "("), indent(unlist(body, use.names = FALSE)), ")")
}

#' Source for a string literal that fits the line width
#'
#' @description Short strings come back as one literal. Longer ones are split
#' on spaces into a `paste()` call, the way the packages already write their
#' long messages by hand.
#'
#' @param x String.
#' @param budget Integer. Maximum characters per chunk, quotes included.
#' Defaults to `66L`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_string <- function(x, budget = 66L) {
  checkmate::qassert(x, "S1")
  checkmate::qassert(budget, "I1[10,)")
  one_line <- deparse_value(x)
  if (nchar(one_line) <= budget) {
    return(one_line)
  }
  words <- strsplit(x, " ", fixed = TRUE)[[1L]]
  chunks <- character(0)
  current <- character(0)
  for (word in words) {
    candidate <- paste(c(current, word), collapse = " ")
    if (length(current) > 0L && nchar(deparse_value(candidate)) > budget) {
      chunks <- c(chunks, paste(current, collapse = " "))
      current <- word
    } else {
      current <- c(current, word)
    }
  }
  chunks <- c(chunks, paste(current, collapse = " "))
  src <- purrr::map_chr(chunks, deparse_value)
  c("paste(", indent(paste0(src, c(rep(",", length(src) - 1L), ""))), ")")
}

#' Put a prefix in front of the first line only
#'
#' @param prefix String. What goes in front.
#' @param lines Character vector. The source lines.
#'
#' @returns Character vector with `prefix` on the first line.
#'
#' @keywords internal
prefix_first <- function(prefix, lines) {
  checkmate::qassert(prefix, "S1")
  checkmate::qassert(lines, "S+")
  lines[[1L]] <- paste0(prefix, lines[[1L]])
  lines
}

#' Deparse a quoted expression, unwrapping an outer brace block
#'
#' @description `quote({ a; b })` deparses with its braces and an extra level
#' of indent. Statements are emitted at the nesting level they land in, so the
#' braces come off.
#'
#' @param expr A language object, or `NULL`.
#' @param budget Integer. Characters available per line once the block has
#' landed at its nesting level. Defaults to `78L`, the 80 character width less
#' the one level of indent the constructor and checker bodies put it at.
#'
#' @returns Character vector of R source lines. Empty for `NULL`.
#'
#' @keywords internal
deparse_block <- function(expr, budget = 78L) {
  if (is.null(expr)) {
    return(character(0))
  }
  checkmate::qassert(budget, "I1[1,)")
  stmts <- if (is.call(expr) && identical(expr[[1L]], as.name("{"))) {
    as.list(expr)[-1L]
  } else {
    list(expr)
  }
  lines <- unlist(
    lapply(stmts, \(stmt) deparse_within(stmt, budget)),
    use.names = FALSE
  )
  # A tighter width.cutoff leaves a trailing space on every broken line.
  halve_indent(sub(" +$", "", lines))
}

#' Deparse one statement, tightening the cutoff if it comes out too wide
#'
#' @description `width.cutoff` is a hint to [base::deparse()], not a limit: the
#' default of 60 happily returns a 95 character line. Nothing can be done about
#' an unbreakable literal, but a call with several arguments does break once
#' the cutoff is low enough, so try that before giving up.
#'
#' @param stmt A language object.
#' @param budget Integer. Characters available per line, measured after
#' [halve_indent()].
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
deparse_within <- function(stmt, budget) {
  checkmate::qassert(budget, "I1[1,)")
  lines <- deparse(stmt)
  if (!any(nchar(halve_indent(lines)) > budget)) {
    return(lines)
  }
  for (cutoff in c(40L, 20L)) {
    retry <- deparse(stmt, width.cutoff = cutoff)
    if (!any(nchar(halve_indent(sub(" +$", "", retry))) > budget)) {
      return(retry)
    }
  }
  lines
}

#' Halve the indentation of deparsed source
#'
#' @description `deparse()` indents nested blocks by four spaces and offers no
#' option to change that. The house style is two.
#'
#' @param lines Character vector of R source lines.
#'
#' @returns Character vector with every leading indent halved.
#'
#' @keywords internal
halve_indent <- function(lines) {
  checkmate::qassert(lines, "S*")
  leading <- nchar(sub("^( *).*$", "\\1", lines))
  paste0(strrep(" ", leading %/% 2L), trimws(lines, which = "left"))
}
