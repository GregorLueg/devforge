# enum emission ----------------------------------------------------------------

## constructors ----------------------------------------------------------------

#' A generated variant constructor
#'
#' @description `<enum>_<variant>()` takes the variant's fields as formals,
#' validates them like a `params_*()` constructor does and returns the tagged
#' list.
#'
#' @param enum A `devforge_enum`.
#' @param variant String. The variant name.
#'
#' @returns Character vector of R source lines, roxygen included.
#'
#' @keywords internal
emit_variant_ctor <- function(enum, variant) {
  checkmate::assertClass(enum, "devforge_enum")
  checkmate::assertChoice(variant, names(enum$variants))
  fields <- enum$variants[[variant]]$fields
  fn_name <- paste0(enum$name, "_", variant)

  roxygen <- c(
    sprintf("#' %s: %s", enum$title, variant),
    "#'",
    wrap_roxygen(enum$variants[[variant]]$doc, prefix = "#' @description "),
    "#'"
  )
  if (length(fields) > 0L) {
    params <- purrr::imap(fields, \(field, name) {
      wrap_roxygen(
        field_doc_prose(field),
        prefix = sprintf("#' @param %s ", name)
      )
    })
    roxygen <- c(roxygen, unlist(params, use.names = FALSE), "#'")
  }
  items <- purrr::imap(fields, \(field, name) {
    wrap_roxygen(
      paste0(name, " - ", field_doc_prose(field)),
      prefix = "#'  \\item ",
      cont = "#'  "
    )
  })
  roxygen <- c(
    roxygen,
    sprintf("#' @returns A `%s` with the following elements:", enum$class),
    "#' \\itemize{",
    sprintf("#'  \\item variant - String. Always `\"%s\"`.", variant),
    unlist(items, use.names = FALSE),
    "#' }",
    "#'",
    if (enum$export) "#' @export" else "#' @keywords internal"
  )

  entries <- c(
    sprintf("variant = \"%s\"", variant),
    sprintf("%s = %s", names(fields), names(fields))
  )
  ret <- c(
    "structure(",
    indent(c(
      "list(",
      indent(paste0(entries, c(rep(",", length(entries) - 1L), ""))),
      "),",
      prefix_first(
        "class = ",
        emit_char_vector(
          c(variant_class(enum, variant), enum$class, "list"),
          budget = 66L
        )
      )
    )),
    ")"
  )
  if (length(fields) == 0L) {
    return(c(
      roxygen,
      paste0(fn_name, " <- function() {"),
      indent(ret),
      "}"
    ))
  }
  c(
    roxygen,
    paste0(fn_name, " <- function("),
    indent(emit_formals(fields)),
    ") {",
    indent(c(
      emit_resolve(fields),
      "# Checks",
      emit_field_checks(fields),
      "",
      "# Return",
      ret
    )),
    "}"
  )
}

#' A generated `as_<enum>()` coercion
#'
#' @description A variant name becomes that variant with its defaults. A list
#' is checked and gets its class rebuilt from `variant`, which `c()`,
#' `unclass()` or a trip through Rust or serialisation may have dropped.
#'
#' @param enum A `devforge_enum`.
#'
#' @returns Character vector of R source lines, roxygen included.
#'
#' @keywords internal
emit_enum_as <- function(enum) {
  checkmate::assertClass(enum, "devforge_enum")
  variants <- names(enum$variants)
  fn_name <- paste0("as_", enum$name)
  classes <- purrr::map_chr(variants, \(v) variant_class(enum, v))
  choice <- prefix_first(
    "checkmate::assertChoice(x, ",
    emit_char_vector(variants, budget = 44L)
  )
  choice[length(choice)] <- paste0(choice[length(choice)], ")")
  c(
    sprintf("#' Coerce to a %s", enum$title),
    "#'",
    wrap_roxygen(
      paste(
        "A variant name becomes that variant with its defaults. A list is",
        "checked and gets its class rebuilt from its `variant` element."
      ),
      prefix = "#' @description "
    ),
    "#'",
    wrap_roxygen(
      sprintf(
        "String or list. One of `%s`, or a value from `%s_*()`.",
        deparse_value(variants),
        enum$name
      ),
      prefix = "#' @param x "
    ),
    "#'",
    sprintf("#' @returns A `%s`.", enum$class),
    "#'",
    if (enum$export) "#' @export" else "#' @keywords internal",
    paste0(fn_name, " <- function(x) {"),
    indent(c(
      "if (checkmate::testString(x)) {",
      indent(c(
        choice,
        "return(switch(",
        indent(c(
          "x,",
          paste0(
            sprintf("%s = %s_%s()", variants, enum$name, variants),
            c(rep(",", length(variants) - 1L), "")
          )
        )),
        "))"
      )),
      "}",
      sprintf("assert%s(x)", enum$class),
      "classes <- c(",
      indent(paste0(
        sprintf("%s = \"%s\"", variants, classes),
        c(rep(",", length(variants) - 1L), "")
      )),
      ")",
      sprintf(
        "class(x) <- c(classes[[x[[\"variant\"]]]], \"%s\", \"list\")",
        enum$class
      ),
      "x"
    )),
    "}"
  )
}

#' A generated exhaustive `match_<enum>()`
#'
#' @description One formal per variant plus `.default`. A missing arm errors
#' upfront, whichever variant is being matched, which is as close to Rust's
#' compile time exhaustiveness as R gets. Arms are functions of the whole
#' value, so fields are read by name and reordering them in the spec cannot
#' silently swap values.
#'
#' @param enum A `devforge_enum`.
#'
#' @returns Character vector of R source lines, roxygen included.
#'
#' @keywords internal
emit_enum_match <- function(enum) {
  checkmate::assertClass(enum, "devforge_enum")
  variants <- names(enum$variants)
  fn_name <- paste0("match_", enum$name)
  msg <- emit_call(
    "sprintf",
    list(
      emit_string(sprintf(
        "Non-exhaustive match on %s, no arm for: %%s.",
        enum$title
      )),
      "paste(absent, collapse = \", \")"
    ),
    budget = 62L
  )
  msg[length(msg)] <- paste0(msg[length(msg)], ",")
  c(
    sprintf("#' Match on a %s", enum$title),
    "#'",
    wrap_roxygen(
      paste(
        "Exhaustive match. Every variant needs an arm unless `.default` is",
        "given, and a missing arm errors whichever variant `x` is. Each arm",
        "is called with the whole value, so fields are read by name."
      ),
      prefix = "#' @description "
    ),
    "#'",
    wrap_roxygen(
      sprintf(
        "A `%s` or a variant name, see [as_%s()].",
        enum$class,
        enum$name
      ),
      prefix = "#' @param x "
    ),
    wrap_roxygen(
      "Function. The arm for that variant.",
      prefix = sprintf("#' @param %s ", paste(variants, collapse = ","))
    ),
    "#' @param .default Function. The arm for every variant without its own.",
    "#'",
    "#' @returns Whatever the matched arm returns.",
    "#'",
    if (enum$export) "#' @export" else "#' @keywords internal",
    paste0(fn_name, " <- function("),
    indent(paste0(
      c("x", variants, ".default"),
      c(rep(",", length(variants) + 1L), "")
    )),
    ") {",
    indent(c(
      sprintf("x <- as_%s(x)", enum$name),
      "given <- c(",
      indent(paste0(
        sprintf("%s = !missing(%s)", variants, variants),
        c(rep(",", length(variants) - 1L), "")
      )),
      ")",
      "absent <- names(given)[!given]",
      "if (length(absent) > 0L && missing(.default)) {",
      indent(c("stop(", indent(c(msg, "call. = FALSE")), ")")),
      "}",
      "arm <- if (given[[x[[\"variant\"]]]]) {",
      indent("get(x[[\"variant\"]], inherits = FALSE)"),
      "} else {",
      indent(".default"),
      "}",
      "checkmate::assertFunction(arm)",
      "arm(x)"
    )),
    "}"
  )
}

#' Everything a package's enum emits into the parameter file
#'
#' @param enum A `devforge_enum`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_enum <- function(enum) {
  checkmate::assertClass(enum, "devforge_enum")
  ctors <- purrr::map(names(enum$variants), \(v) {
    c(emit_variant_ctor(enum, v), "")
  })
  c(
    unlist(ctors, use.names = FALSE),
    emit_enum_as(enum),
    "",
    emit_enum_match(enum),
    ""
  )
}

## checker ---------------------------------------------------------------------

#' A generated `check<Enum>()` and its assertion sibling
#'
#' @description Delegates to the prelude's `check_enum_value()` with a table of
#' the fields, qtest patterns and choice sets per variant.
#'
#' @param enum A `devforge_enum`.
#'
#' @returns Character vector of R source lines, roxygen included.
#'
#' @keywords internal
emit_enum_checker <- function(enum) {
  checkmate::assertClass(enum, "devforge_enum")
  check_name <- paste0("check", enum$class)
  assert_name <- paste0("assert", enum$class)
  entries <- purrr::imap(enum$variants, \(variant, name) {
    fields <- variant$fields
    if (length(fields) == 0L) {
      return(sprintf("%s = list(fields = character(0))", name))
    }
    is_choice <- purrr::map_lgl(fields, \(f) identical(f$type, "choice"))
    parts <- list(prefix_first(
      "fields = ",
      emit_char_vector(names(fields), budget = 56L)
    ))
    if (any(!is_choice)) {
      rules <- purrr::map(fields[!is_choice], field_qassert, for_check = TRUE)
      parts <- c(parts, list(prefix_first("rules = ", emit_rules_list(rules))))
    }
    if (any(is_choice)) {
      choices <- purrr::map(fields[is_choice], \(f) f$choices)
      parts <- c(
        parts,
        list(prefix_first("choices = ", emit_rules_list(choices)))
      )
    }
    parts <- purrr::imap(parts, \(p, i) {
      if (i < length(parts)) p[length(p)] <- paste0(p[length(p)], ",")
      p
    })
    c(
      sprintf("%s = list(", name),
      indent(unlist(parts, use.names = FALSE)),
      ")"
    )
  })
  entries <- purrr::imap(unname(entries), \(e, i) {
    if (i < length(entries)) e[length(e)] <- paste0(e[length(e)], ",")
    e
  })
  c(
    sprintf("#' Check %s", enum$title),
    "#'",
    wrap_roxygen(
      sprintf(
        "Checkmate extension for the `%s` enum, see [as_%s()].",
        enum$class,
        enum$name
      ),
      prefix = "#' @description "
    ),
    "#'",
    "#' @param x The object to check.",
    "#'",
    "#' @returns `TRUE` if the check was successful, otherwise a",
    "#' checkmate-style error string.",
    "#'",
    "#' @keywords internal",
    paste0(check_name, " <- function(x) {"),
    indent(c(
      "check_enum_value(",
      indent(c(
        "x,",
        "variants = list(",
        indent(unlist(entries, use.names = FALSE)),
        "),",
        paste0("label = ", deparse_value(enum$title))
      )),
      ")"
    )),
    "}",
    "",
    sprintf("#' Assert %s", enum$title),
    "#'",
    sprintf("#' @inheritParams %s", check_name),
    "#' @param .var.name Name of the checked object to print in assertions.",
    "#' @param add Collection to store assertion messages. See",
    "#' [checkmate::makeAssertCollection()].",
    "#'",
    "#' @returns Invisibly returns the checked object if the assertion is",
    "#' successful.",
    "#'",
    "#' @keywords internal",
    prefix_first(
      paste0(assert_name, " <- "),
      emit_call(
        "checkmate::makeAssertionFunction",
        list(check_name),
        budget = 80L - nchar(assert_name) - 4L
      )
    )
  )
}

## impl blocks -----------------------------------------------------------------

#' The S3 generics declared by a package's enums
#'
#' @description One generic per method name. Two enums declaring the same
#' method share the generic, the first enum's title wins.
#'
#' @param enums List of `devforge_enum` objects.
#'
#' @returns Character vector of R source lines, roxygen included. Empty when
#' no enum declares a method.
#'
#' @keywords internal
emit_enum_generics <- function(enums) {
  checkmate::assertList(enums, types = "devforge_enum")
  pairs <- purrr::map(enums, \(e) {
    purrr::imap(
      e$methods,
      \(title, m) list(method = m, title = title, enum = e)
    )
  }) |>
    unlist(recursive = FALSE, use.names = FALSE)
  if (length(pairs) == 0L) {
    return(character(0))
  }
  methods <- unique(purrr::map_chr(pairs, \(p) p$method))
  out <- purrr::map(methods, \(m) {
    owners <- purrr::keep(pairs, \(p) identical(p$method, m))
    classes <- purrr::map_chr(owners, \(p) p$enum$class)
    export <- any(purrr::map_lgl(owners, \(p) p$enum$export))
    c(
      wrap_roxygen(owners[[1L]]$title, prefix = "#' "),
      "#'",
      wrap_roxygen(
        sprintf(
          paste(
            "S3 generic over the %s enum(s). Methods are written per",
            "variant class (`<Enum>_<Variant>`) or for the enum class as the",
            "fallback."
          ),
          paste(sprintf("`%s`", classes), collapse = ", ")
        ),
        prefix = "#' @description "
      ),
      "#'",
      "#' @param self An enum value.",
      "#' @param ... Passed on to the methods.",
      "#'",
      "#' @returns Whatever the method returns.",
      "#'",
      if (export) "#' @export" else "#' @keywords internal",
      sprintf("%s <- function(self, ...) {", m),
      indent(sprintf("UseMethod(\"%s\")", m)),
      "}",
      ""
    )
  })
  unlist(out, use.names = FALSE)
}

#' The functions a package defines at the top level of its hand-written code
#'
#' @description Parses rather than sources, so the package does not need to
#' load. The generated files are skipped.
#'
#' @param pkg String. Path to the package root.
#'
#' @returns Character vector of the names assigned at the top level.
#'
#' @keywords internal
top_level_names <- function(pkg) {
  checkmate::assertDirectoryExists(pkg)
  files <- list.files(
    file.path(pkg, "R"),
    pattern = "\\.[Rr]$",
    full.names = TRUE
  )
  files <- files[!basename(files) %in% basename(GENERATED_FILES)]
  names <- purrr::map(files, \(file) {
    purrr::map_chr(as.list(parse(file, keep.source = FALSE)), \(expr) {
      is_assign <- is.call(expr) &&
        as.character(expr[[1L]])[[1L]] %in% c("<-", "=") &&
        (is.name(expr[[2L]]) || is.character(expr[[2L]]))
      if (is_assign) as.character(expr[[2L]]) else NA_character_
    })
  }) |>
    unlist(use.names = FALSE)
  names[!is.na(names)]
}

#' Check that every variant implements every method of its enum
#'
#' @description The counterpart of Rust's non-exhaustive match error for impl
#' blocks. A variant passes when the package defines
#' `<method>.<Enum>_<Variant>` or the fallback `<method>.<Enum>`.
#'
#' @param pkg String. Path to the package root.
#' @param enums List of `devforge_enum` objects.
#'
#' @returns `TRUE`, invisibly. Errors listing every gap otherwise.
#'
#' @keywords internal
check_enum_methods <- function(pkg, enums) {
  checkmate::assertDirectoryExists(pkg)
  checkmate::assertList(enums, types = "devforge_enum")
  defined <- top_level_names(pkg)
  gaps <- purrr::map(enums, \(e) {
    purrr::map(names(e$methods), \(m) {
      if (paste0(m, ".", e$class) %in% defined) {
        return(NULL)
      }
      missing_variants <- purrr::keep(names(e$variants), \(v) {
        !paste0(m, ".", variant_class(e, v)) %in% defined
      })
      if (length(missing_variants) == 0L) {
        return(NULL)
      }
      sprintf(
        "  %s() on %s: %s",
        m,
        e$class,
        paste(missing_variants, collapse = ", ")
      )
    })
  }) |>
    unlist(use.names = FALSE)
  if (length(gaps) > 0L) {
    stop(
      sprintf(
        paste0(
          "Enum methods without an implementation. Add a method per ",
          "variant or one for the enum class:\n%s"
        ),
        paste(gaps, collapse = "\n")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

## references ------------------------------------------------------------------

#' Check that every enum field points at a known enum and variant
#'
#' @param specs List of `devforge_spec` objects.
#' @param enums Named list of `devforge_enum` objects.
#'
#' @returns `TRUE`, invisibly. Errors otherwise.
#'
#' @keywords internal
assert_enum_refs <- function(specs, enums) {
  checkmate::assertList(specs, types = "devforge_spec")
  checkmate::assertList(enums, types = "devforge_enum")
  purrr::walk(specs, \(s) {
    purrr::iwalk(s$fields, \(f, name) {
      if (!identical(f$type, "enum")) {
        return(NULL)
      }
      enum <- enums[[f$enum]]
      if (is.null(enum)) {
        stop(sprintf(
          "Field `%s` of spec `%s` refers to enum `%s`, which is not defined.",
          name,
          s$name,
          f$enum
        ))
      }
      if (!f$default %in% names(enum$variants)) {
        stop(sprintf(
          "Field `%s` of spec `%s` defaults to `%s`, not a variant of `%s`.",
          name,
          s$name,
          f$default,
          f$enum
        ))
      }
    })
  })
  invisible(TRUE)
}
