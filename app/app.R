# LLM Evaluation Results Shiny App
# ============================================================================

library(shiny)
library(bslib)
library(gt)

# Source helper functions
source(here::here("app/R/data_loading.R"))
source(here::here("app/R/plotting.R"))

# ============================================================================
# Load Data
# ============================================================================

# Load model prices
model_prices <- load_model_prices(here::here("app/data/model_prices.yaml"))

# Load evaluation results
tasks <- load_eval_results(here::here("results_rds"))

# Process evaluation data
are_eval_full <- process_eval_data(tasks)

# Compute cost data
are_costs <- compute_cost_data(tasks, model_prices)

# Get available models
available_models <- get_available_models(are_eval_full)

# ============================================================================
# UI
# ============================================================================

ui <- page_sidebar(
  title = "LLM Evaluation Results Explorer",
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  sidebar = sidebar(
    title = "Model Selection",
    width = 300,

    checkboxGroupInput(
      "selected_models",
      "Select models to compare:",
      choices = setNames(
        available_models$model_join,
        available_models$model_display
      ),
      selected = available_models$model_join[1:5]
    ),

    hr(),

    actionButton(
      "select_all",
      "Select All",
      class = "btn-sm btn-outline-primary",
      width = "48%"
    ),
    actionButton(
      "clear_all",
      "Clear All",
      class = "btn-sm btn-outline-secondary",
      width = "48%"
    ),

    hr(),

    p(
      class = "text-muted small",
      "This app displays evaluation results from the vitals package, ",
      "comparing LLM performance on R code generation tasks."
    )
  ),

  navset_card_tab(
    nav_panel(
      "Performance",
      card(
        card_header("Model Performance on R Code Generation"),
        card_body(
          plotOutput("performance_plot", height = "600px")
        )
      )
    ),

    nav_panel(
      "Cost vs Performance",
      card(
        card_header("Cost vs Performance Analysis"),
        card_body(
          plotOutput("cost_plot", height = "600px")
        )
      )
    ),

    nav_panel(
      "Pricing Details",
      card(
        card_header("Model Pricing and Token Usage"),
        card_body(
          gt_output("pricing_table")
        )
      )
    )
  )
)

# ============================================================================
# Server
# ============================================================================

server <- function(input, output, session) {
  # Reactive: Filtered evaluation data
  filtered_eval <- reactive({
    req(input$selected_models)

    are_eval_full |>
      filter(model_join %in% input$selected_models)
  })

  # Reactive: Summary statistics
  eval_summary <- reactive({
    req(input$selected_models)

    compute_summary_stats(
      are_eval_full,
      are_costs,
      input$selected_models
    )
  })

  # Select/Clear all buttons
  observeEvent(input$select_all, {
    updateCheckboxGroupInput(
      session,
      "selected_models",
      selected = available_models$model_join
    )
  })

  observeEvent(input$clear_all, {
    updateCheckboxGroupInput(
      session,
      "selected_models",
      selected = character(0)
    )
  })

  # ============================================================================
  # Outputs
  # ============================================================================

  # Performance plot (stacked bar chart)
  output$performance_plot <- renderPlot({
    req(nrow(filtered_eval()) > 0)

    plot_performance(filtered_eval())
  })

  # Cost vs Performance scatter plot
  output$cost_plot <- renderPlot({
    req(nrow(eval_summary()) > 0)

    plot_cost_vs_performance(eval_summary())
  })

  # Pricing table
  output$pricing_table <- render_gt({
    req(nrow(eval_summary()) > 0)

    eval_summary() |>
      left_join(model_prices, by = "model_join") |>
      select(
        Model = model_display,
        `Input (per 1M tokens)` = Input,
        `Output (per 1M tokens)` = Output,
        `Input Tokens Used` = input,
        `Output Tokens Used` = output,
        `Total Cost` = price
      ) |>
      gt() |>
      fmt_currency(
        columns = c(
          `Input (per 1M tokens)`,
          `Output (per 1M tokens)`,
          `Total Cost`
        ),
        currency = "USD",
        decimals = 2
      ) |>
      fmt_number(
        columns = c(`Input Tokens Used`, `Output Tokens Used`),
        decimals = 0
      ) |>
      tab_header(
        title = "Model Pricing Details",
        subtitle = "Pricing per 1 million tokens and actual usage in evaluation"
      )
  })
}

# ============================================================================
# Run App
# ============================================================================

shinyApp(ui = ui, server = server)
