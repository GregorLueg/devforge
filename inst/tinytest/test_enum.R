# enums modelled on bixverse ---------------------------------------------------

# svd_solver in params_sc_pca(): two unit variants and one with a payload
pca_solver <- param_enum(
  name = "pca_solver",
  title = "PCA solver",
  variants = list(
    covariance = p_variant("Eigendecomposition of the cross-product."),
    randomised = p_variant(
      "Randomised SVD.",
      oversample = p_int(10L, range = "[0,)", doc = "Extra columns."),
      n_iter = p_int(2L, range = "[0,)", doc = "Power iterations.")
    ),
    exact = p_variant("Lanczos on the sparse path, full SVD on the dense one.")
  )
)

# learner_type + learner_params + gene_batch_* in params_scenic(), where the
# batch fields are "ignored for grnboost2"
batch_strategy <- \() {
  p_choice("correlated", c("random", "correlated"), doc = "Batching.")
}
batch_size <- \() {
  p_int(NULL, range = "[1,)", null_ok = TRUE, doc = "Genes per batch.")
}
regression_learner <- param_enum(
  name = "regression_learner",
  title = "regression learner",
  variants = list(
    randomforest = p_variant(
      "Random forest.",
      n_trees = p_int(250L, range = "[1,)", doc = "Number of trees."),
      max_depth = p_int(8L, range = "[1,)", doc = "Maximum depth."),
      subsample_frac = p_dbl(
        NULL,
        range = "(0,1]",
        null_ok = TRUE,
        doc = "Subsample fraction."
      ),
      gene_batch_strategy = batch_strategy(),
      gene_batch_size = batch_size()
    ),
    extratrees = p_variant(
      "Extremely randomised trees.",
      n_trees = p_int(500L, range = "[1,)", doc = "Number of trees."),
      n_thresholds = p_int(1L, range = "[1,)", doc = "Random thresholds."),
      gene_batch_strategy = batch_strategy(),
      gene_batch_size = batch_size()
    ),
    grnboost2 = p_variant(
      "Gradient boosting with early stopping.",
      n_trees_max = p_int(1000L, range = "[1,)", doc = "Maximum trees."),
      learning_rate = p_dbl(0.01, range = "(0,1]", doc = "Learning rate."),
      early_stop_window = p_int(25L, range = "[1,)", doc = "Stop window.")
    )
  )
)

# generator in the synthetic bulk data params, where factor_std only applies
# to two generators and factor_scale doubles as the Laplace scale
synthetic_generator <- param_enum(
  name = "synthetic_generator",
  title = "synthetic data generator",
  variants = list(
    hub_modular = p_variant(
      "Modules with hub genes.",
      factor_std = p_dbl(0.5, range = "(0,)", doc = "Normal factor SD."),
      hub_percentile = p_dbl(0.1, range = "(0,1]", doc = "Hub fraction.")
    ),
    modular = p_variant(
      "Modules without hubs.",
      factor_std = p_dbl(0.5, range = "(0,)", doc = "Normal factor SD.")
    ),
    non_negative_factor = p_variant(
      "Gamma factor.",
      factor_shape = p_dbl(2, range = "(0,)", doc = "Gamma shape."),
      factor_scale = p_dbl(0.3, range = "(0,)", doc = "Gamma scale.")
    ),
    non_gaussian_factor = p_variant(
      "Laplace factor.",
      laplace_scale = p_dbl(0.3, range = "(0,)", doc = "Laplace scale.")
    )
  )
)

scenic <- param_spec(
  name = "scenic",
  title = "Wrapper function for SCENIC parameters",
  fields = list(
    min_cells = p_dbl(0.03, range = "(0,1]", doc = "Minimum cell fraction."),
    learner = p_enum("regression_learner", "randomforest", doc = "Learner.")
  )
)

specs <- list(
  pca_solver = pca_solver,
  regression_learner = regression_learner,
  scenic = scenic,
  synthetic_generator = synthetic_generator
)
rendered <- devforge:::render_specs(specs)

# the house style caps every line at 80 characters, before air touches it
expect_true(all(nchar(unlist(rendered, use.names = FALSE)) <= 80L))

env <- new.env(parent = globalenv())
eval(parse(text = unlist(rendered, use.names = FALSE)), envir = env)

# constructors -----------------------------------------------------------------

rs <- env$pca_solver_randomised(n_iter = 4L)
expect_equal(
  unclass(rs),
  list(variant = "randomised", oversample = 10L, n_iter = 4L)
)
expect_equal(class(rs), c("PcaSolver_Randomised", "PcaSolver", "list"))
expect_error(env$pca_solver_randomised(n_iter = -1L))
expect_equal(unclass(env$pca_solver_exact()), list(variant = "exact"))

# a choice field inside a variant resolves with match.arg
rf <- env$regression_learner_randomforest()
expect_equal(rf$gene_batch_strategy, "correlated")
expect_null(rf$gene_batch_size)
expect_error(env$regression_learner_randomforest(gene_batch_strategy = "x"))

# coercion ---------------------------------------------------------------------

expect_equal(env$as_regression_learner("grnboost2")$n_trees_max, 1000L)
expect_error(env$as_pca_solver("lanczos"))

# a bare list gets its class back from the variant element
bare <- unclass(env$synthetic_generator_modular())
expect_equal(
  class(env$as_synthetic_generator(bare)),
  c("SyntheticGenerator_Modular", "SyntheticGenerator", "list")
)

# checker ----------------------------------------------------------------------

expect_true(env$checkRegressionLearner(rf))

# a field that belongs to another variant is rejected, which is the point
gb <- env$regression_learner_grnboost2()
gb$gene_batch_size <- 100L
expect_true(grepl("gene_batch_size", env$checkRegressionLearner(gb)))

# and so is a missing one
gen <- env$synthetic_generator_hub_modular()
gen$hub_percentile <- NULL
expect_false(isTRUE(env$checkSyntheticGenerator(gen)))

# payload rules and choice sets per variant
gen <- env$synthetic_generator_non_gaussian_factor()
gen$laplace_scale <- 0
expect_true(grepl("laplace_scale", env$checkSyntheticGenerator(gen)))
rf$gene_batch_strategy <- "anything"
expect_false(isTRUE(env$checkRegressionLearner(rf)))
expect_true(grepl("variant", env$checkPcaSolver(list(variant = "nope"))))

# params constructor -----------------------------------------------------------

# a string keeps working and comes back as the full variant
p <- env$params_scenic(learner = "extratrees")
expect_equal(p$learner$n_trees, 500L)
expect_true(env$checkScenicParams(p))
expect_equal(env$params_scenic()$learner$variant, "randomforest")
p <- env$params_scenic(learner = env$regression_learner_grnboost2(25L))
expect_equal(p$learner$n_trees_max, 25L)
p$learner$n_trees <- 10L
expect_true(grepl("`learner`", env$checkScenicParams(p)))

# match ------------------------------------------------------------------------

n_trees <- \(learner) {
  env$match_regression_learner(
    learner,
    randomforest = \(v) v$n_trees,
    extratrees = \(v) v$n_trees,
    grnboost2 = \(v) v$n_trees_max
  )
}
expect_equal(n_trees("grnboost2"), 1000L)
expect_equal(n_trees(env$regression_learner_extratrees(n_trees = 7L)), 7L)

# a missing arm errors even when the value matched has its own arm
expect_error(
  env$match_pca_solver("covariance", covariance = \(v) 1),
  "no arm for: randomised, exact"
)
expect_equal(
  env$match_pca_solver("exact", covariance = \(v) 1, .default = \(v) 2),
  2
)
expect_error(env$match_pca_solver("exact", exact = 1, .default = \(v) 2))

# spec validation --------------------------------------------------------------

expect_error(p_variant("x", variant = p_int(1L, doc = "Tag.")), "reserved")
expect_error(p_variant("x", n = p_int(doc = "No default.")), "default")
expect_error(
  param_enum("e", "e", variants = list(x = p_variant("x"))),
  "snake_case"
)
expect_error(
  param_defaults(
    name = "d",
    title = "d",
    fields = list(s = p_enum("pca_solver", "exact", doc = "Solver."))
  ),
  "p_enum"
)
expect_error(
  devforge:::render_specs(list(scenic = scenic)),
  "not defined"
)
bad_default <- param_spec(
  name = "bad",
  title = "bad",
  fields = list(s = p_enum("pca_solver", "lanczos", doc = "Solver."))
)
expect_error(
  devforge:::render_specs(list(pca_solver = pca_solver, bad = bad_default)),
  "not a variant"
)

# packages without enums keep the old prelude
expect_false(any(grepl(
  "check_enum_value",
  devforge:::render_specs(list(
    scenic = param_spec(
      name = "plain",
      title = "plain",
      fields = list(k = p_int(1L, doc = "K."))
    )
  ))$prelude
)))

# impl blocks ------------------------------------------------------------------

pkg <- file.path(tempdir(), "devforge-enum-test")
unlink(pkg, recursive = TRUE)
dir.create(file.path(pkg, "inst", "params"), recursive = TRUE)
dir.create(file.path(pkg, "R"), recursive = TRUE)

writeLines(
  c(
    'enum_solver <- param_enum(',
    '  name = "pca_solver",',
    '  title = "PCA solver",',
    '  variants = list(',
    '    covariance = p_variant("Covariance."),',
    '    randomised = p_variant(',
    '      "Randomised.",',
    '      n_iter = p_int(2L, range = "[0,)", doc = "Power iterations.")',
    '    ),',
    '    exact = p_variant("Exact.")',
    '  ),',
    '  methods = list(is_exact = "Exactness", describe = "Describe it")',
    ')',
    '',
    'enum_gen <- param_enum(',
    '  name = "generator",',
    '  title = "generator",',
    '  variants = list(',
    '    modular = p_variant("Modular."),',
    '    gamma = p_variant("Gamma.")',
    '  ),',
    '  methods = list(describe = "Describe it")',
    ')'
  ),
  file.path(pkg, "inst", "params", "enums.R")
)

methods_file <- file.path(pkg, "R", "methods.R")
writeLines(
  c(
    "is_exact.PcaSolver <- function(self, ...) TRUE",
    "is_exact.PcaSolver_Randomised <- function(self, ...) FALSE",
    "describe.PcaSolver <- function(self, ...) self$variant",
    "describe.Generator_Modular <- function(self, ...) 'modular'"
  ),
  methods_file
)

# generator_gamma has neither its own describe() nor a Generator fallback
expect_error(
  forge_params(pkg, .verbose = FALSE),
  "describe\\(\\) on Generator: gamma"
)
expect_error(params_up_to_date(pkg), "gamma")

# the enum class fallback covers the remaining variants
write(
  "describe.Generator <- function(self, ...) 'other'",
  methods_file,
  append = TRUE
)
paths <- forge_params(pkg, .verbose = FALSE)
expect_true(isTRUE(params_up_to_date(pkg)))

generated <- readLines(file.path(pkg, "R", "params-generated.R"))
expect_equal(sum(grepl('UseMethod("describe")', generated, fixed = TRUE)), 1L)

env <- new.env(parent = globalenv())
for (path in c(paths, methods_file)) {
  sys.source(path, envir = env, keep.source = FALSE)
}
# UseMethod() looks for methods where the generic is called, and nothing is
# registered here as it would be in a package, so dispatch runs inside env
expect_false(evalq(is_exact(pca_solver_randomised()), env))
expect_true(evalq(is_exact(as_pca_solver("exact")), env))
expect_equal(evalq(describe(pca_solver_covariance()), env), "covariance")
expect_equal(evalq(describe(generator_modular()), env), "modular")
expect_equal(evalq(describe(generator_gamma()), env), "other")

unlink(pkg, recursive = TRUE)
