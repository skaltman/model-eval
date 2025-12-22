# Data Loading and Processing Functions for Shiny App
# ============================================================================

library(purrr)
library(dplyr)
library(tibble)
library(vitals)
library(fs)
library(yaml)

#' Load model info (pricing, provider, and release date) from YAML file
#' Generates default and standardized variants for each model
#'
#' @param yaml_path Path to models.yaml file
#' @return A tibble with columns: Name, model_join, provider, release_date, Input, Output, api_model_id, configuration
load_model_info <- function(yaml_path = "data/models.yaml") {
  prices_raw <- read_yaml(yaml_path)

  prices_raw$models |>
    map(\(model) {
      # Shared fields
      base_info <- list(
        Name = model$name,
        provider = model$provider,
        release_date = model$release_date,
        Input = model$input_price,
        Output = model$output_price,
        api_model_id = model$api_model_id %||% NA_character_
      )

      # List to collect variants
      variants <- list()

      # Default variant (always)
      default_variant <- c(base_info, list(
        model_join = model$model_id,
        configuration = "default",
        default_params_description = model$default_params_description %||% NA_character_
      ))
      variants <- append(variants, list(default_variant))

      # Alternative config variants (if specified)
      if (!is.null(model$alternative_configs)) {
        for (alt_config in model$alternative_configs) {
          alt_variant <- c(base_info, list(
            model_join = paste0(model$model_id, "_", alt_config$config_name),
            configuration = alt_config$config_name
          ))
          variants <- append(variants, list(alt_variant))
        }
      }

      variants
    }) |>
    flatten() |>
    map_dfr(\(variant) as_tibble(variant))
}

#' Load all evaluation results from RDS files
#'
#' @param results_dir Directory containing .rds files
#' @return Named list of Task objects
load_eval_results <- function(results_dir = "results_rds") {
  dir_ls(results_dir, glob = "*.rds") |>
    set_names(\(x) path_ext_remove(basename(x))) |>
    map(readr::read_rds)
}

#' Process evaluation data into tidy format
#'
#' @param tasks Named list of Task objects from load_eval_results()
#' @param model_info Model info tibble from load_model_info()
#' @return Tibble with columns: model_join, model_display_base, model_display_full, score, etc.
process_eval_data <- function(tasks, model_info) {
  # Extract base model name (for grouping)
  base_name_lookup <- model_info |>
    select(model_id = model_join, display_name = Name) |>
    deframe()

  # Extract full display name with config suffix (for plotting)
  full_name_lookup <- model_info |>
    select(model_id = model_join, display_name = Name, configuration) |>
    mutate(
      display_name = case_when(
        configuration == "default" ~ display_name,
        configuration == "thinking_1024" ~ paste0(display_name, " (thinking 1024)"),
        configuration == "reasoning_medium" ~ paste0(display_name, " (reasoning medium)"),
        TRUE ~ paste0(display_name, " (", configuration, ")")
      )
    ) |>
    select(model_id, display_name) |>
    deframe()

  tasks |>
    imap(
      \(x, idx) {
        vitals_bind(x) |>
          mutate(model_raw = idx)
      }
    ) |>
    list_rbind() |>
    mutate(
      model_join = model_raw,
      # Base name for grouping in sidebar
      model_display_base = if_else(
        model_raw %in% names(base_name_lookup),
        base_name_lookup[model_raw],
        model_raw
      ),
      # Full name with config for plot labels
      model_display = if_else(
        model_raw %in% names(full_name_lookup),
        full_name_lookup[model_raw],
        model_raw
      ) |>
        as.factor(),
      score = forcats::fct_recode(
        as.factor(score),
        "Correct" = "C",
        "Partially Correct" = "P",
        "Incorrect" = "I"
      )
    )
}

#' Compute cost data from tasks and model prices
#'
#' @param tasks Named list of Task objects
#' @param model_prices Tibble from load_model_prices()
#' @return Tibble with cost data including input/output tokens and total price
compute_cost_data <- function(tasks, model_prices) {
  tasks |>
    imap(\(x, idx) x$get_cost() |> mutate(model_join = idx)) |>
    list_rbind() |>
    filter(source != "scorer") |>
    mutate(price = stringr::str_extract(price, "\\d+\\.\\d+") |> as.double()) |>
    left_join(model_prices, by = "model_join") |>
    mutate(
      price = if_else(
        is.na(price),
        input * Input / 1e6 + output * Output / 1e6,
        price
      )
    ) |>
    select(model = Name, model_id = model, model_join, input, output, price)
}

#' Get list of available models for selection
#'
#' @param eval_data Processed evaluation data from process_eval_data()
#' @return Tibble with model_display and model_join columns
get_available_models <- function(eval_data) {
  eval_data |>
    distinct(model_display, model_join) |>
    arrange(model_display)
}

#' Compute summary statistics for selected models
#'
#' @param eval_data Processed evaluation data
#' @param cost_data Cost data from compute_cost_data()
#' @param selected_models Character vector of model_join IDs
#' @return Tibble with summary statistics per model
compute_summary_stats <- function(eval_data, cost_data, selected_models) {
  eval_data |>
    filter(model_join %in% selected_models) |>
    group_by(model_display, model_join) |>
    summarize(
      total_samples = n(),
      correct = sum(score == "Correct"),
      partially_correct = sum(score == "Partially Correct"),
      incorrect = sum(score == "Incorrect"),
      percent_correct = correct / total_samples,
      .groups = "drop"
    ) |>
    left_join(
      cost_data |> select(model_join, price, input, output),
      by = "model_join"
    ) |>
    arrange(desc(percent_correct))
}
