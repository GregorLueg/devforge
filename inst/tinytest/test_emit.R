# emitted source ---------------------------------------------------------------

spec <- param_spec(
  name = "demo",
  title = "Wrapper function for demo parameters",
  fields = list(
    maxit = p_int(200L, range = "[1,)", doc = "Maximum number of iterations."),
    alpha = p_dbl(1, range = "[1, 2]", doc = "Alpha of the algorithm."),
    budget = p_int(NULL, null_ok = TRUE, doc = "Optional search budget."),
    method = p_choice("a", c("a", "b"), doc = "Which method to run."),
    verbose = p_lgl(FALSE, doc = "Controls verbosity.")
  ),
  hint = "See `params_demo()`."
)

ctor <- devforge:::emit_ctor(spec)
checker <- devforge:::emit_checker(spec)

# the house style caps every line at 80 characters
expect_true(all(nchar(c(ctor, checker, devforge:::emit_prelude())) <= 80L))

# choice fields resolve with match.arg and are asserted, not qasserted
expect_true(any(grepl("method <- match.arg(method)", ctor, fixed = TRUE)))
expect_true(any(grepl(
  'checkmate::assertChoice(method, c("a", "b"))',
  ctor,
  fixed = TRUE
)))
expect_false(any(grepl('qassert(method', ctor, fixed = TRUE)))

# whole doubles keep the decimal point, nullable ints get the "0" alternative
expect_true(any(grepl("alpha = 1.0,", ctor, fixed = TRUE)))
expect_true(any(grepl(
  'checkmate::qassert(budget, c("I1", "0"))',
  ctor,
  fixed = TRUE
)))

# the checker is three calls into the shared helpers
expect_true(any(grepl("check_list_shape(", checker, fixed = TRUE)))
expect_true(any(grepl("apply_qtest_rules(", checker, fixed = TRUE)))
expect_true(any(grepl("apply_choice_rules(", checker, fixed = TRUE)))
expect_true(any(grepl(
  "assertDemoParams <- checkmate::makeAssertionFunction(",
  checker,
  fixed = TRUE
)))

# behaviour of the generated code ----------------------------------------------

env <- new.env(parent = globalenv())
eval(parse(text = c(devforge:::emit_prelude(), ctor, checker)), envir = env)

params <- env$params_demo()
expect_equal(
  params,
  list(maxit = 200L, alpha = 1, budget = NULL, method = "a", verbose = FALSE)
)
expect_true(isTRUE(env$checkDemoParams(params)))

# every field rejects the wrong type
expect_false(isTRUE(env$checkDemoParams(modifyList(params, list(maxit = "x")))))
expect_false(isTRUE(env$checkDemoParams(modifyList(params, list(alpha = 5)))))
expect_false(isTRUE(env$checkDemoParams(modifyList(
  params,
  list(method = "z")
))))
expect_false(isTRUE(env$checkDemoParams(params[setdiff(
  names(params),
  "alpha"
)])))

# nullable fields take NULL or a value, extras pass while strict_names is off
expect_true(isTRUE(env$checkDemoParams(modifyList(params, list(budget = 5L)))))
expect_true(isTRUE(env$checkDemoParams(c(params, list(extra = 1L)))))

# the constructor validates at the door
expect_error(env$params_demo(alpha = 5))
expect_error(env$params_demo(maxit = 0L))
expect_error(env$params_demo(method = "z"))
expect_equal(env$params_demo(method = "b")$method, "b")

# strict_names ------------------------------------------------------------------

strict <- spec
strict$strict_names <- TRUE
env_strict <- new.env(parent = globalenv())
eval(
  parse(text = c(devforge:::emit_prelude(), devforge:::emit_checker(strict))),
  envir = env_strict
)
expect_true(isTRUE(env_strict$checkDemoParams(params)))
expect_false(isTRUE(env_strict$checkDemoParams(c(params, list(extra = 1L)))))

# defaults blocks ----------------------------------------------------------------

defaults <- param_defaults(
  name = "knn_defaults",
  title = "Helper function to generate kNN defaults",
  fields = list(
    k = p_int(15L, doc = "Number of neighbours."),
    method = p_choice("kmknn", c("kmknn", "hnsw"), doc = "Which method.")
  )
)
env_def <- new.env(parent = globalenv())
eval(parse(text = devforge:::emit_ctor(defaults)), envir = env_def)
expect_equal(env_def$params_knn_defaults(), list(k = 15L, method = "kmknn"))
expect_equal(length(formals(env_def$params_knn_defaults)), 0L)

# class tags and shared checkers -------------------------------------------------

tagged <- spec
tagged$class_tag <- "params_demo"
env_tag <- new.env(parent = globalenv())
eval(parse(text = devforge:::emit_ctor(tagged)), envir = env_tag)
expect_true(inherits(env_tag$params_demo(), "params_demo"))
expect_true(is.list(env_tag$params_demo()))

other <- spec
other$name <- "demo_two"
expect_equal(length(devforge:::dedupe_checkers(list(spec, other))), 1L)

mismatch <- other
mismatch$fields <- spec$fields[1:2]
expect_error(devforge:::dedupe_checkers(list(spec, mismatch)))

# regressions --------------------------------------------------------------------

# a hint used to put the argument separator on a line of its own
expect_false(any(grepl("^ *,$", checker)))
expect_true(any(grepl('label = "demo params",', checker, fixed = TRUE)))

# the assert and test siblings are documented, not bare
expect_true(any(grepl("#' Assert demo params", checker, fixed = TRUE)))
expect_true(any(grepl(
  "#' @inheritParams checkDemoParams",
  checker,
  fixed = TRUE
)))

tested <- spec
tested$test_fn <- TRUE
expect_true(any(grepl(
  "#' Test demo params",
  devforge:::emit_checker(tested),
  fixed = TRUE
)))

# deparse() treats width.cutoff as a hint, so a wide extra block was emitted
# verbatim at 95 characters
wide <- spec
wide$extra_ctor <- quote({
  checkmate::assertTRUE(
    maxit > alpha,
    .var.name = "maxit has to exceed alpha, which is a long name"
  )
})
expect_true(all(nchar(devforge:::emit_ctor(wide)) <= 80L))

# and no line keeps the trailing space a tighter cutoff leaves behind
expect_false(any(grepl(" $", devforge:::emit_ctor(wide))))
