# constructor emission ---------------------------------------------------------

## roxygen ---------------------------------------------------------------------

# Prose type annotation per field type. The generator writes these rather than
# the spec, so the documented type can never disagree with the qassert pattern.
FIELD_TYPE_PROSE <- c(
  int = "Integer",
  dbl = "Numeric",
  lgl = "Boolean",
  chr = "String",
  choice = "String",
  free = "Any"
)

#' The documented default of a field
#'
#' @description For a choice field the formal default is the whole set of
#' choices, but what is documented is the first one, which is what `match.arg()`
#' picks.
#'
#' @param field A `devforge_field`.
#'
#' @returns The value that the field takes when the caller passes nothing.
#'
#' @keywords internal
field_effective_default <- function(field) {
  checkmate::assertClass(field, "devforge_field")
  if (identical(field$type, "choice")) field$choices[[1L]] else field$default
}

#' The source text of a field's formal default
#'
#' @param field A `devforge_field`.
#'
#' @returns String. R source for the right hand side of the formal.
#'
#' @keywords internal
field_formal_default <- function(field) {
  checkmate::assertClass(field, "devforge_field")
  if (identical(field$type, "choice")) {
    deparse_value(field$choices)
  } else if (identical(field$type, "dbl")) {
    deparse_double(field$default)
  } else {
    deparse_value(field$default)
  }
}

#' The source text of a field's value in a defaults block
#'
#' @description A defaults block has no formals, so a choice field contributes
#' the resolved default rather than the whole set of choices.
#'
#' @param field A `devforge_field`.
#'
#' @returns String. R source for the value.
#'
#' @keywords internal
field_value_src <- function(field) {
  checkmate::assertClass(field, "devforge_field")
  value <- field_effective_default(field)
  if (identical(field$type, "dbl")) {
    deparse_double(value)
  } else {
    deparse_value(value)
  }
}

#' The roxygen prose for one field
#'
#' @description Type annotation, the spec's prose, the allowed choices where
#' there are any, and the default. The last two are derived rather than written
#' by hand, which is the point.
#'
#' @param field A `devforge_field`.
#'
#' @returns String. One sentence run, unwrapped.
#'
#' @keywords internal
field_doc_prose <- function(field) {
  checkmate::assertClass(field, "devforge_field")
  plural <- !identical(field$len, 1L) && !identical(field$len, 1)
  type <- unname(FIELD_TYPE_PROSE[[field$type]])
  if (plural) {
    type <- paste(type, "vector")
  }
  if (field$null_ok) {
    type <- paste(type, "or `NULL`")
  }
  parts <- paste0(type, ". ", field$doc)
  if (identical(field$type, "choice")) {
    parts <- paste0(
      parts,
      sprintf(" One of %s.", paste0("`", deparse_value(field$choices), "`"))
    )
  }
  default_src <- if (identical(field$type, "dbl")) {
    deparse_double(field_effective_default(field))
  } else {
    deparse_value(field_effective_default(field))
  }
  paste0(parts, sprintf(" Defaults to `%s`.", default_src))
}

#' The `\itemize{}` block describing a spec's returned list
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of roxygen lines.
#'
#' @keywords internal
roxygen_itemize <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  ordered <- spec$fields[spec_field_names(spec)]
  items <- purrr::imap(ordered, \(field, name) {
    wrap_roxygen(
      paste0(name, " - ", field_doc_prose(field)),
      prefix = "#'  \\item ",
      cont = "#'  "
    )
  })
  c("#' \\itemize{", unlist(items, use.names = FALSE), "#' }")
}

#' The roxygen block for a generated constructor
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of roxygen lines.
#'
#' @keywords internal
emit_ctor_roxygen <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  lines <- wrap_roxygen(spec$title, prefix = "#' ")
  if (!is.null(spec$description)) {
    lines <- c(
      lines,
      "#'",
      wrap_roxygen(spec$description, prefix = "#' @description ")
    )
  }
  if (!is.null(spec$details)) {
    lines <- c(
      lines,
      "#'",
      "#' @details",
      paste0("#' ", strsplit(spec$details, "\n", fixed = TRUE)[[1L]])
    )
  }
  if (!spec$defaults_only) {
    params <- purrr::imap(spec$fields, \(field, name) {
      wrap_roxygen(
        field_doc_prose(field),
        prefix = sprintf("#' @param %s ", name)
      )
    })
    lines <- c(lines, "#'", unlist(params, use.names = FALSE))
  }
  lines <- c(
    lines,
    "#'",
    "#' @returns A named list with the following elements:",
    roxygen_itemize(spec)
  )
  if (!is.null(spec$references)) {
    lines <- c(
      lines,
      "#'",
      wrap_roxygen(spec$references, prefix = "#' @references ")
    )
  }
  if (spec$export) {
    lines <- c(lines, "#'", "#' @export")
  } else {
    lines <- c(lines, "#'", "#' @keywords internal")
  }
  lines
}

## body ------------------------------------------------------------------------

#' The assertion lines for a generated constructor
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_ctor_checks <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  purrr::imap(spec$fields, \(field, name) {
    pattern <- field_qassert(field)
    lines <- character(0)
    if (identical(field$type, "choice")) {
      return(sprintf(
        "checkmate::assertChoice(%s, %s)",
        name,
        deparse_value(field$choices)
      ))
    }
    if (!is.null(pattern)) {
      lines <- sprintf(
        "checkmate::qassert(%s, %s)",
        name,
        deparse_value(pattern)
      )
    }
    lines
  }) |>
    unlist(use.names = FALSE)
}

#' A generated `params_*()` constructor
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of R source lines, roxygen included.
#'
#' @keywords internal
emit_ctor <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  fn_name <- paste0("params_", spec$name)
  names_vec <- names(spec$fields)
  ret_names <- spec_field_names(spec)
  body_list <- c(
    "list(",
    indent(paste0(
      ret_names,
      " = ",
      if (spec$defaults_only) {
        purrr::map_chr(spec$fields[ret_names], field_value_src)
      } else {
        ret_names
      },
      c(rep(",", length(ret_names) - 1L), "")
    )),
    ")"
  )
  if (!is.null(spec$class_tag)) {
    body_list <- c(
      paste0("res <- ", body_list[[1L]]),
      body_list[-1L],
      sprintf("class(res) <- c(%s, \"list\")", deparse_value(spec$class_tag)),
      "res"
    )
  }
  if (spec$defaults_only) {
    return(c(
      emit_ctor_roxygen(spec),
      paste0(fn_name, " <- function() {"),
      indent(body_list),
      "}"
    ))
  }
  choices <- names_vec[purrr::map_lgl(
    spec$fields,
    \(f) identical(f$type, "choice")
  )]
  resolve <- if (length(choices) > 0L) {
    c(sprintf("%s <- match.arg(%s)", choices, choices), "")
  } else {
    character(0)
  }
  extra <- if (!is.null(spec$extra_ctor)) {
    c("", deparse_block(spec$extra_ctor))
  } else {
    character(0)
  }
  formals_src <- paste0(
    names_vec,
    " = ",
    purrr::map_chr(spec$fields, field_formal_default),
    c(rep(",", length(names_vec) - 1L), "")
  )
  c(
    emit_ctor_roxygen(spec),
    paste0(fn_name, " <- function("),
    indent(formals_src),
    ") {",
    indent(c(
      resolve,
      "# Checks",
      emit_ctor_checks(spec),
      extra,
      "",
      "# Return",
      body_list
    )),
    "}"
  )
}
