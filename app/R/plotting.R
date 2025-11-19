# Plotting Functions for Shiny App
# ============================================================================

library(ggplot2)
library(ggrepel)
library(scales)

#' Create performance bar chart
#'
#' @param eval_data Filtered evaluation data with model_display and score columns
#' @return ggplot object
plot_performance <- function(eval_data) {
  # Reorder models by correct count
  eval_data <- eval_data |>
    mutate(
      model_display = fct_reorder(
        model_display,
        score,
        .fun = \(x) sum(x == "Correct", na.rm = TRUE)
      )
    )

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
      title = "Model Performance on R Code Generation",
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
#' @param summary_data Summary statistics with percent_correct and price columns
#' @return ggplot object
plot_cost_vs_performance <- function(summary_data) {
  # Convert factor to character for labeling
  plot_data <- summary_data |>
    mutate(model_display = as.character(model_display))

  # Calculate means for reference lines
  mean_correct <- mean(plot_data$percent_correct, na.rm = TRUE)
  mean_price <- mean(plot_data$price, na.rm = TRUE)

  ggplot(plot_data, aes(price, percent_correct)) +
    geom_point(size = 3, color = "#2c3e50") +
    geom_hline(
      yintercept = mean_correct,
      color = "#666666",
      linewidth = 0.8,
      alpha = 0.4,
      linetype = "dashed"
    ) +
    geom_vline(
      xintercept = mean_price,
      color = "#666666",
      linewidth = 0.8,
      alpha = 0.4,
      linetype = "dashed"
    ) +
    geom_label_repel(
      aes(label = model_display),
      force = 1,
      max.overlaps = 20,
      size = 3.5,
      fill = "#f5f5f5",
      color = "#333333"
    ) +
    scale_x_continuous(labels = label_dollar()) +
    scale_y_continuous(
      labels = label_percent(),
      breaks = breaks_width(0.05)
    ) +
    labs(
      x = "Total Cost (USD)",
      y = "Percent Correct",
      title = "Model Performance vs. Cost",
      subtitle = "Dashed lines show mean values across selected models"
    ) +
    theme_light() +
    theme(
      plot.subtitle = element_text(face = "italic", size = 11),
      axis.title = element_text(size = 14),
      title = element_text(size = 16),
      axis.text = element_text(size = 12)
    )
}
