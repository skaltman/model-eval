# Helper Functions for Shiny App
# ============================================================================

library(ggplot2)
library(ggrepel)
library(scales)
library(dplyr)
library(forcats)

# Data Helper Functions ------------------------------------------------------

#' Get list of available models for selection
#'
#' @param eval_data Processed evaluation data
#' @return Tibble with model_display_base, model_display, and model_join columns
get_available_models <- function(eval_data) {
  eval_data |>
    distinct(model_display_base, model_display, model_join) |>
    arrange(model_display_base, model_display)
}

#' Compute summary statistics for selected models
#'
#' @param eval_data Processed evaluation data
#' @param cost_data Cost data
#' @param selected_models Character vector of model_join IDs
#' @param model_info Model metadata with provider information
#' @return Tibble with summary statistics per model
compute_summary_stats <- function(
  eval_data,
  cost_data,
  selected_models,
  model_info
) {
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
    left_join(
      model_info |> select(model_join, provider),
      by = "model_join"
    ) |>
    arrange(desc(percent_correct))
}

# Plotting Functions ---------------------------------------------------------

#' Create performance bar chart
#'
#' @param eval_data Filtered evaluation data with model_display and score columns
#' @return ggplot object
plot_performance <- function(eval_data) {
  # Ordering is already established in the data's factor levels
  eval_data |>
    ggplot(aes(y = model_display, fill = score)) +
    geom_bar(position = "fill") +
    scale_fill_manual(
      breaks = rev,
      values = c(
        "Correct" = "#6caea7",
        "Partially Correct" = "#f6e8c3",
        "Incorrect" = "#ef8a62"
      )
    ) +
    scale_x_continuous(labels = percent, expand = c(5e-3, 5e-3)) +
    labs(
      x = "Percent",
      y = NULL,
      fill = "Score"
    ) +
    theme_light() +
    theme(
      legend.position = "bottom",
      plot.margin = margin(10, 10, 10, 10),
      axis.title = element_text(size = 14),
      title = element_text(size = 16),
      axis.text = element_text(size = 12),
      legend.text = element_text(size = 12)
    )
}

#' Create cost vs performance scatter plot
#'
#' @param summary_data Summary statistics with percent_correct, price, and provider columns
#' @return ggplot object
plot_cost_vs_performance <- function(summary_data) {
  # Convert factor to character for labeling
  plot_data <- summary_data |>
    mutate(model_display = as.character(model_display))

  # Calculate means for reference lines
  mean_correct <- mean(plot_data$percent_correct, na.rm = TRUE)
  mean_price <- mean(plot_data$price, na.rm = TRUE)

  # Add color column based on provider
  plot_data <- plot_data |>
    mutate(
      color = case_when(
        provider == "Anthropic" ~ "#be8bd4ff",
        provider == "OpenAI" ~ "#80c8d3ff",
        provider == "Google" ~ "#f6e8c3"
      )
    )

  # Adjust min.segment.length based on number of models
  n_models <- nrow(plot_data)
  min_seg_length <- if_else(n_models < 10, 1.2, 0.5)

  ggplot(plot_data, aes(price, percent_correct, color = provider)) +
    geom_point(size = 5) +
    geom_label_repel(
      aes(
        label = model_display,
        fill = alpha(color, 0.8),
        segment.color = color
      ),
      force = 3,
      max.overlaps = 20,
      size = 7,
      color = "#333333",
      show.legend = FALSE,
      min.segment.length = min_seg_length,
      box.padding = 0.5
    ) +
    scale_color_identity(aesthetics = "segment.color") +
    scale_fill_identity() +
    scale_x_continuous(labels = label_dollar()) +
    scale_y_continuous(
      labels = label_percent(),
      breaks = breaks_width(0.05)
    ) +
    scale_color_manual(
      values = c(
        "Anthropic" = "#be8bd4ff",
        "OpenAI" = "#80c8d3ff",
        "Google" = "#f6e8c3"
      )
    ) +
    labs(
      x = "Total Cost (USD)",
      y = "Percent Correct",
      color = "Provider"
    ) +
    theme_light() +
    theme(
      plot.subtitle = element_text(face = "italic", size = 12),
      plot.margin = margin(10, 10, 20, 10),
      axis.title = element_text(size = 14),
      title = element_text(size = 16),
      axis.text = element_text(size = 12),
      legend.position = "bottom",
      legend.text = element_text(size = 12)
    )
}

# Table Functions ------------------------------------------------------------

#' Create pricing and performance table
#'
#' @param summary_data Summary statistics with percent_correct, price, and token usage
#' @param model_info Model metadata with pricing information
#' @return gt table object
create_pricing_table <- function(summary_data, model_info) {
  summary_data |>
    left_join(model_info, by = "model_join") |>
    arrange(desc(percent_correct)) |>
    select(
      Model = model_display,
      `Input (per 1M tokens)` = Input,
      `Output (per 1M tokens)` = Output,
      `Input Tokens Used` = input,
      `Output Tokens Used` = output,
      `Total Cost` = price,
      `% Correct` = percent_correct
    ) |>
    gt::gt() |>
    gt::fmt_currency(
      columns = c(
        `Input (per 1M tokens)`,
        `Output (per 1M tokens)`,
        `Total Cost`
      ),
      currency = "USD",
      decimals = 2
    ) |>
    gt::fmt_number(
      columns = c(`Input Tokens Used`, `Output Tokens Used`),
      decimals = 0,
      use_seps = TRUE
    ) |>
    gt::fmt_percent(
      columns = `% Correct`,
      decimals = 1
    ) |>
    gt::cols_align(
      align = "left",
      columns = everything()
    ) |>
    gt::tab_header(
      title = "Model Pricing and Performance Details",
      subtitle = "Sorted by percent correct (descending)"
    ) |>
    gt::data_color(
      columns = `% Correct`,
      palette = c("#ef8a62", "#f6e8c3", "#6caea7"),
      domain = NULL
    ) |>
    gt::data_color(
      columns = `Total Cost`,
      palette = c("#e8f4f8", "#a8d5e2", "#6baed6", "#3182bd", "#08519c"),
      domain = NULL
    ) |>
    gt::tab_options(
      table.font.size = gt::px(14),
      heading.title.font.size = gt::px(18),
      heading.subtitle.font.size = gt::px(14),
      column_labels.font.weight = "bold",
      ihtml.use_pagination = FALSE,
      ihtml.use_page_size_select = FALSE,
      table.width = gt::pct(100)
    )
}
