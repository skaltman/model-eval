library(yaml)
library(fs)
library(glue)
library(purrr)
library(dplyr)

# ============================================================================
# YAML parsing
# ============================================================================

#' Parse YAML and extract model configurations
#'
#' @param yaml_path Path to model_info.yaml
#' @return List of model configs, each with evaluation parameters
parse_model_configs <- function(yaml_path) {
  yaml_data <- read_yaml(yaml_path)

  models <- yaml_data$models %>%
    map(function(model) {
      # Validate required fields
      required <- c(
        "name",
        "model_id",
        "provider",
        "api_model_id",
        "input_price",
        "output_price",
        "release_date"
      )
      missing <- setdiff(required, names(model))
      if (length(missing) > 0) {
        stop(glue(
          "Model '{model$name}' missing required fields: {paste(missing, collapse=', ')}"
        ))
      }

      # Build config with defaults for optional fields
      config <- list(
        name = model$name,
        model_id = model$model_id,
        api_model_id = model$api_model_id,
        provider = model$provider,
        thinking = model$thinking %||% FALSE,
        thinking_budget = model$thinking_budget %||% 2000,
        base_url = model$base_url %||% NULL,
        api_key_env = model$api_key_env %||% NULL
      )

      config
    })

  # Name the list by model_id for easy lookup
  names(models) <- map_chr(models, "model_id")
  models
}

#' Check which models have already been evaluated
#'
#' @param model_configs List of model configs from parse_model_configs()
#' @param results_dir Directory containing .rds files
#' @return Character vector of model_ids that have NOT been evaluated
find_unevaluated_models <- function(model_configs, results_dir) {
  all_model_ids <- names(model_configs)

  # Create results_dir if it doesn't exist
  if (!dir_exists(results_dir)) {
    dir_create(results_dir)
    return(all_model_ids) # All models are unevaluated
  }

  existing_files <- dir_ls(results_dir, glob = "*.rds") %>%
    path_file() %>%
    path_ext_remove()

  unevaluated <- setdiff(all_model_ids, existing_files)
  unevaluated
}

#' Build ellmer chat() arguments from model config
#'
#' @param config Model config from parse_model_configs()
#' @return Named list of arguments to pass to chat()
build_chat_args <- function(config) {
  args <- list()

  # Add base_url if specified
  if (!is.null(config$base_url)) {
    args$base_url <- config$base_url
  }

  # Add custom API key if specified
  if (!is.null(config$api_key_env)) {
    api_key <- Sys.getenv(config$api_key_env)
    if (api_key == "") {
      stop(glue(
        "Environment variable '{config$api_key_env}' not set for model '{config$name}'"
      ))
    }
    args$api_key <- api_key
  }

  # Add api_args if specified in YAML
  if (!is.null(config$api_args)) {
    args$api_args <- config$api_args
  }

  args
}

# ============================================================================
# Evaluation Execution Functions
# ============================================================================

#' Run evaluation for a single model with error handling
#'
#' @param model_id The model_id from YAML
#' @param config Model configuration
#' @param model_eval_fn The model_eval function to call
#' @param results_dir Directory to save results
#' @param scorer_chat Chat object used for model-graded scoring
#' @return TRUE if successful, FALSE if failed
run_single_eval <- function(
  model_id,
  config,
  model_eval_fn,
  results_dir,
  scorer_chat
) {
  message(glue("\n{strrep('=', 70)}"))
  message(glue("Evaluating: {config$name} ({model_id})"))
  message(glue("API Model: {config$api_model_id}"))
  message(glue("{strrep('=', 70)}\n"))

  result <- tryCatch(
    {
      # Build chat arguments
      chat_args <- build_chat_args(config)

      # Call model_eval with dynamic arguments
      do.call(
        model_eval_fn,
        c(
          list(
            model = config$api_model_id,
            filename = model_id,
            scorer_chat = scorer_chat,
            overwrite = FALSE # Don't overwrite existing results
          ),
          chat_args
        )
      )

      message(glue("✓ Successfully evaluated {config$name}"))
      TRUE
    },
    error = function(e) {
      message(glue("✗ FAILED: {config$name}"))
      message(glue("  Error: {e$message}"))
      FALSE
    }
  )

  result
}

#' Run all unevaluated models
#'
#' @param model_configs List of all model configs
#' @param unevaluated_ids Vector of model_ids to evaluate
#' @param model_eval_fn The model_eval function to call
#' @param results_dir Directory to save results
#' @param scorer_chat Chat object used for model-graded scoring
#' @return Named logical vector (TRUE = success, FALSE = failure)
run_all_evals <- function(
  model_configs,
  unevaluated_ids,
  model_eval_fn,
  results_dir,
  scorer_chat
) {
  if (length(unevaluated_ids) == 0) {
    message("No models to evaluate. All models have existing results.")
    return(logical(0))
  }

  message(glue("\nFound {length(unevaluated_ids)} model(s) to evaluate:\n"))
  walk(
    unevaluated_ids,
    ~ message(glue("  - {model_configs[[.x]]$name} ({.x})"))
  )
  message("")

  # Run evaluations
  results <- map_lgl(
    unevaluated_ids,
    function(model_id) {
      config <- model_configs[[model_id]]
      run_single_eval(model_id, config, model_eval_fn, results_dir, scorer_chat)
    }
  )

  names(results) <- unevaluated_ids
  results
}

# ============================================================================
# Result Combining Function
# ============================================================================

#' Combine all evaluation results and save to data/data_combined.rds
#'
#' @param yaml_path Path to model_info.yaml
#' @param results_dir Directory containing .rds files
#' @param load_model_info_fn Function to load model info
#' @param load_eval_results_fn Function to load eval results
#' @param process_eval_data_fn Function to process eval data
#' @param compute_cost_data_fn Function to compute cost data
#' @return TRUE if successful, FALSE if failed
combine_results <- function(
  yaml_path,
  results_dir,
  load_model_info_fn,
  load_eval_results_fn,
  process_eval_data_fn,
  compute_cost_data_fn
) {
  tryCatch(
    {
      # Load model info
      model_info <- load_model_info_fn(yaml_path)

      # Load evaluation results
      tasks <- load_eval_results_fn(results_dir)

      if (length(tasks) == 0) {
        message("No evaluation results found")
        return(FALSE)
      }

      # Process evaluation data
      are_eval_full <- process_eval_data_fn(tasks, model_info)

      # Extract minimal data for app
      eval_data_minimal <- are_eval_full |>
        select(model_join, model_display, score)

      # Compute cost data
      are_costs <- compute_cost_data_fn(tasks, model_info)

      # Combine into app_data structure
      app_data <- list(
        eval_data = eval_data_minimal,
        cost_data = are_costs,
        model_info = model_info
      )

      # Save combined data
      output_path <- here::here("data/data_combined.rds")
      readr::write_rds(app_data, output_path)

      message(glue(
        "Combined {nrow(model_info)} models → {basename(output_path)}"
      ))

      TRUE
    },
    error = function(e) {
      message(glue("Error combining results: {e$message}"))
      FALSE
    }
  )
}
