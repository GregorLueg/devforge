# enum emission ----------------------------------------------------------------

## helper ----------------------------------------------------------------------

# Emitted at the top of R/enums-generated.R. Self-contained, so the enums file
# works without the params prelude in a package that has no params specs.
ENUM_HELPER_SOURCE <- '#\' Check a tagged enum value
#\'
#\' @description Verifies that `x` is a list whose `variant` is one of
#\' `names(variants)` and whose other names are exactly that variant\'s fields,
#\' then validates the fields with their qtest patterns, choice sets and the
#\' checkers of nested enums.
#\'
#\' @param x The object to check.
#\' @param variants Named list, one entry per variant, each a list with
#\' `fields` (character vector) and optionally `rules` (named list of qtest
#\' patterns), `choices` (named list of allowed values) and `enums` (named list
#\' of checker functions).
#\' @param label Short human-readable label used in the error message.
#\'
#\' @returns `TRUE` if the check was successful, otherwise a checkmate-style
#\' error string.
#\'
#\' @keywords internal
check_enum_value <- function(x, variants, label) {
  res <- checkmate::checkList(x)
  if (!isTRUE(res)) {
    return(res)
  }
  res <- checkmate::checkChoice(x[["variant"]], names(variants))
  if (!isTRUE(res)) {
    return(sprintf("The `variant` of %s is invalid: %s", label, res))
  }
  spec <- variants[[x[["variant"]]]]
  label <- sprintf("%s variant `%s`", label, x[["variant"]])
  res <- checkmate::checkSetEqual(names(x), c("variant", spec$fields))
  if (!isTRUE(res)) {
    return(sprintf("The names of %s are invalid: %s", label, res))
  }
  for (name in names(spec$rules)) {
    if (!checkmate::qtest(x[[name]], spec$rules[[name]])) {
      return(sprintf("The element `%s` in %s is invalid.", name, label))
    }
  }
  for (name in names(spec$choices)) {
    if (!checkmate::testChoice(x[[name]], spec$choices[[name]])) {
      return(sprintf(
        "The element `%s` in %s is not one of the expected choices.",
        name,
        label
      ))
    }
  }
  for (name in names(spec$enums)) {
    res <- spec$enums[[name]](x[[name]])
    if (!isTRUE(res)) {
      return(sprintf(
        "The element `%s` in %s is invalid. %s",
        name,
        label,
        res
      ))
    }
  }
  TRUE
}'

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
#' @description A variant name becomes that variant with its defaults, or an
#' error for a variant with required fields. A list is checked and gets its
#' class rebuilt from `variant`, which `c()`, `unclass()` or a trip through
#' Rust or serialisation may have dropped.
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
  arms <- purrr::map_chr(variants, \(v) {
    if (variant_from_name(enum, v)) {
      sprintf("%s = %s_%s()", v, enum$name, v)
    } else {
      sprintf("%s = stop(\"Build `%s` with %s_%s().\")", v, v, enum$name, v)
    }
  })
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
        "A variant name becomes that variant with its defaults, as long as",
        "it carries no required fields. A list is checked and gets its class",
        "rebuilt from its `variant` element."
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
          paste0(arms, c(rep(",", length(variants) - 1L), ""))
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

#' Everything one enum emits
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
    section_header(enum$name),
    "",
    unlist(ctors, use.names = FALSE),
    emit_enum_as(enum),
    "",
    emit_enum_match(enum),
    "",
    emit_enum_checker(enum),
    ""
  )
}

#' The source of `R/enums-generated.R`
#'
#' @param enums List of `devforge_enum` objects.
#'
#' @returns Character vector of R source lines, without the generated header.
#'
#' @keywords internal
emit_enums_file <- function(enums) {
  checkmate::assertList(enums, types = "devforge_enum", min.len = 1L)
  generics <- emit_enum_generics(enums)
  c(
    section_header("enum helper"),
    "",
    strsplit(ENUM_HELPER_SOURCE, "\n", fixed = TRUE)[[1L]],
    "",
    unlist(purrr::map(enums, emit_enum), use.names = FALSE),
    if (length(generics) > 0L) {
      c(section_header("enum methods"), "", generics)
    }
  )
}

## checker ---------------------------------------------------------------------

#' A generated `check<Enum>()` and its assertion sibling
#'
#' @description Delegates to the emitted `check_enum_value()` with a table of
#' the fields, qtest patterns, choice sets and nested enum checkers per
#' variant. Free fields are only required to be present.
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
    type <- purrr::map_chr(fields, \(f) f$type)
    parts <- list(prefix_first(
      "fields = ",
      emit_char_vector(names(fields), budget = 56L)
    ))
    rules <- purrr::map(
      fields[!type %in% c("choice", "enum", "free")],
      field_qassert,
      for_check = TRUE
    )
    if (length(rules) > 0L) {
      parts <- c(parts, list(prefix_first("rules = ", emit_rules_list(rules))))
    }
    if (any(type == "choice")) {
      choices <- purrr::map(fields[type == "choice"], \(f) f$choices)
      parts <- c(
        parts,
        list(prefix_first("choices = ", emit_rules_list(choices)))
      )
    }
    if (any(type == "enum")) {
      nested <- purrr::imap_chr(fields[type == "enum"], \(f, name) {
        sprintf("%s = check%s", name, to_pascal_case(f$enum))
      })
      parts <- c(
        parts,
        list(c(
          "enums = list(",
          indent(paste0(nested, c(rep(",", length(nested) - 1L), ""))),
          ")"
        ))
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
#' @description Covers the fields of the specs and the payloads of the enums'
#' own variants. A default has to name a variant that can be built from its
#' name alone.
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
  owners <- c(
    purrr::map(specs, \(s) {
      list(where = sprintf("spec `%s`", s$name), fields = s$fields)
    }),
    unlist(
      purrr::map(enums, \(e) {
        purrr::imap(e$variants, \(v, vname) {
          list(
            where = sprintf("enum `%s_%s`", e$name, vname),
            fields = v$fields
          )
        })
      }),
      recursive = FALSE,
      use.names = FALSE
    )
  )
  purrr::walk(owners, \(o) {
    purrr::iwalk(o$fields, \(f, name) {
      if (!identical(f$type, "enum")) {
        return(NULL)
      }
      enum <- enums[[f$enum]]
      if (is.null(enum)) {
        stop(sprintf(
          "Field `%s` of %s refers to enum `%s`, which is not defined.",
          name,
          o$where,
          f$enum
        ))
      }
      if (f$required) {
        return(NULL)
      }
      ok <- f$default %in%
        names(enum$variants) &&
        variant_from_name(enum, f$default)
      if (!ok) {
        stop(sprintf(
          paste(
            "Field `%s` of %s defaults to `%s`, not a variant of `%s` that",
            "can be built from its name."
          ),
          name,
          o$where,
          f$default,
          f$enum
        ))
      }
    })
  })
  invisible(TRUE)
}
