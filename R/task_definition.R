# This file defines:
# - are_task: The evaluation task configuration (dataset, solver, scorer)
# - model_eval(): Core function to evaluate a single model

library(ellmer)
library(vitals)

# Set results directory
results_dir <- here::here("results_rds")

# Define the evaluation task
# This task uses the ARE (An R Eval) dataset from the vitals package
# Models are evaluated on R coding problems with model-graded scoring
are_task <- Task$new(
  dataset = are,
  solver = generate(),
  scorer = model_graded_qa(
    scorer_chat = scorer_chat,
    partial_credit = TRUE
  ),
  epochs = 3, # Run 3 evaluation rounds
  name = "An R Eval"
)

#' Evaluate a model on the ARE dataset
#'
#' @param model API model identifier (e.g., "anthropic/claude-sonnet-4-20250514")
#' @param filename Output filename (without .rds extension). Defaults to model name.
#' @param overwrite Whether to overwrite existing results. Defaults to TRUE.
#' @param ... Additional arguments passed to chat():
#'   - base_url: Custom API endpoint
#'   - api_key: Custom API key
#'   - api_args: List of additional API arguments (e.g., thinking config)
#'
#' @return Invisible NULL. Results saved to results_rds/{filename}.rds
#'
#' @examples
#' # Standard evaluation
#' model_eval("anthropic/claude-sonnet-4-20250514", filename = "sonnet_4")
#'
#' # With thinking enabled
#' model_eval(
#'   "anthropic/claude-sonnet-4-20250514",
#'   filename = "sonnet_4_thinking",
#'   api_args = list(thinking = list(type = "enabled", budget_tokens = 2000))
#' )
#'
#' # With custom endpoint
#' model_eval(
#'   "openai/gpt-oss-20b",
#'   filename = "gpt_oss_20b",
#'   base_url = "https://custom.endpoint.com/v1",
#'   api_key = Sys.getenv("CUSTOM_API_KEY")
#' )
model_eval <- function(
  model,
  filename = model,
  overwrite = TRUE,
  ...
) {
  model_path <- fs::path(results_dir, filename, ext = "rds")

  if (!overwrite & fs::file_exists(model_path)) {
    message(glue::glue("Skipping {model}: file already exists at {model_path}"))
    return(invisible(NULL))
  }

  chat <- chat(name = model, ...)

  are_model <- are_task$clone()
  are_model$eval(solver_chat = chat)

  readr::write_rds(are_model, file = model_path)
}
