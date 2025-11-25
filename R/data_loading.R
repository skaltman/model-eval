# Data Loading and Processing Functions for Shiny App
# ============================================================================

library(tidyverse)
library(vitals)
library(fs)
library(yaml)

#' Load model pricing data from YAML file
#'
#' @param yaml_path Path to model_prices.yaml file
#' @return A tibble with columns: Name, model_join, Input, Output
load_model_prices <- function(yaml_path = "data/model_prices.yaml") {
  prices_raw <- read_yaml(yaml_path)

  prices_raw$models |>
    map_dfr(\(model) {
      tibble(
        Name = model$name,
        model_join = model$model_id,
        Input = model$input_price,
        Output = model$output_price
      )
    })
}

#' Load all evaluation results from RDS files
#'
#' @param results_dir Directory containing .rds files
#' @return Named list of Task objects
load_eval_results <- function(results_dir = "results_rds") {
  dir_ls(results_dir, glob = "*.rds") |>
    set_names(\(x) path_ext_remove(basename(x))) |>
    map(read_rds)
}

#' Process evaluation data into tidy format
#'
#' @param tasks Named list of Task objects from load_eval_results()
#' @return Tibble with columns: model_raw, model_join, model_display, score, etc.
process_eval_data <- function(tasks) {
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
      model_display = fct_recode(
        model_raw,
        `Claude Sonnet 4 (No Thinking)` = "sonnet_4",
        `Claude Sonnet 4` = "sonnet_4_thinking",
        `Claude Sonnet 4.5` = "sonnet_4_5_thinking",
        `Claude Opus 4.1` = "opus_4_1_thinking",
        `Claude Haiku 4.5` = "haiku_4_5_thinking",
        `GPT-4.1` = "gpt_4_1",
        `GPT-5.1` = "gpt_5_1",
        `o1` = "gpt_o1",
        `o3-mini` = "gpt_o3_mini",
        `o3` = "gpt_o3",
        `o4-mini` = "gpt_o4_mini",
        `GPT-5` = "gpt_5",
        `GPT-5 mini` = "gpt_5_mini",
        `GPT-5 nano` = "gpt_5_nano",
        `gpt-oss-20b` = "gpt_oss_20b",
        `gpt-oss-120b` = "gpt_oss_120b",
        `Gemini 3` = "gemini_3"
      ),
      score = fct_recode(
        score,
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
    mutate(price = str_extract(price, "\\d+\\.\\d+") |> as.double()) |>
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
    left_join(cost_data |> select(model_join, price, input, output), by = "model_join") |>
    arrange(desc(percent_correct))
}
