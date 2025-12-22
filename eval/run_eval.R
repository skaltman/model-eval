# Runs the `are` eval for models listed in data/models.yaml
# Will skip models that have already been run (by looking in results_rds)
# Combines all rds results into data/data_combined.rds
#
# Usage:
#   Rscript eval/run_eval.R                    # Run all unevaluated models
#   Rscript eval/run_eval.R --provider=Google  # Run only Google models
#   Rscript eval/run_eval.R --provider=Anthropic

library(ellmer)
library(vitals)
library(purrr)
library(glue)

# Source helper functions
source(here::here("R/task_definition.R"))
source(here::here("R/data_loading.R"))
source(here::here("R/eval_functions.R"))

# Configuration
YAML_PATH <- here::here("data/models.yaml")
RESULTS_DIR <- here::here("results_rds")
LOG_DIR <- here::here("logs")
SCORER_MODEL <- "anthropic/claude-sonnet-4-20250514"

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
provider_filter <- NULL

if (length(args) > 0) {
  provider_arg <- args[grep("^--provider=", args)]
  if (length(provider_arg) > 0) {
    provider_filter <- sub("^--provider=", "", provider_arg[1])
    message(glue("Filtering to provider: {provider_filter}"))
  }
}

# Set up logging
vitals::vitals_log_dir_set(LOG_DIR)

# ============================================================================
# Run Evaluation
# ============================================================================

# Parse YAML configuration
model_configs <- parse_model_configs(YAML_PATH)

# Filter by provider if specified
if (!is.null(provider_filter)) {
  providers <- map_chr(model_configs, "provider")
  matching <- providers == provider_filter

  if (sum(matching) == 0) {
    stop(glue("No models found for provider: {provider_filter}"))
  }

  model_configs <- model_configs[matching]
  message(glue(
    "Found {length(model_configs)} model(s) for provider {provider_filter}"
  ))
}

# Find unevaluated models
unevaluated <- find_unevaluated_models(model_configs, RESULTS_DIR)

# Run evaluations if needed
if (length(unevaluated) > 0) {
  message(glue("Running {length(unevaluated)} unevaluated model(s)..."))

  scorer_chat <- chat(name = SCORER_MODEL)

  eval_results <- run_all_evals(
    model_configs = model_configs,
    unevaluated_ids = unevaluated,
    model_eval_fn = model_eval,
    results_dir = RESULTS_DIR,
    scorer_chat = scorer_chat
  )

  # Report failures only
  n_failed <- sum(!eval_results)
  if (n_failed > 0) {
    message(glue("\nWarning: {n_failed} model(s) failed"))
    failed_ids <- names(eval_results)[!eval_results]
    walk(failed_ids, ~ message(glue("  - {model_configs[[.x]]$name}")))
  }
}

# Combine results
combine_results(
  yaml_path = YAML_PATH,
  results_dir = RESULTS_DIR,
  load_model_info_fn = load_model_info,
  load_eval_results_fn = load_eval_results,
  process_eval_data_fn = process_eval_data,
  compute_cost_data_fn = compute_cost_data
)
