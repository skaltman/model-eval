# Runs the `are` eval for models listed in data/models.yaml
# Will skip models that have already been run (by looking in results_rds)
# Combines all rds results into data/data_combined.rds

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
SCORER_MODEL <- "claude-3-7-sonnet-latest"

# Set up logging
vitals::vitals_log_dir_set(LOG_DIR)

# ============================================================================
# Run Evaluation
# ============================================================================

# Parse YAML configuration
model_configs <- parse_model_configs(YAML_PATH)

# Find unevaluated models
unevaluated <- find_unevaluated_models(model_configs, RESULTS_DIR)

# Run evaluations if needed
if (length(unevaluated) > 0) {
  message(glue("Running {length(unevaluated)} unevaluated model(s)..."))

  scorer_chat <- chat_anthropic(model = SCORER_MODEL)

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
