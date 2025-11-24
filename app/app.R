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

ui <- page_navbar(
  title = "R Code Generation: LLM Evaluation Results",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  id = "main_nav",

  nav_panel(
    "Results",
    page_sidebar(
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
            card_header("Model Performance vs. Cost"),
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
              class = "p-0",
              gt_output("pricing_table")
            )
          )
        )
      )
    )
  ),

  nav_panel(
    "About",
    layout_columns(
      col_widths = c(2, 8, 2),
      NULL,
      div(
        style = "padding-top: 20px;",
        h2("About This Evaluation"),

        h4("Overview"),
        p(
          "This app displays evaluation results comparing how well various Large Language Models (LLMs) ",
          "generate R code. With many AI coding assistants available, this evaluation helps you choose ",
          "the best model for R programming tasks."
        ),

        h4("Methodology"),
        tags$ul(
          tags$li(
            strong("Framework: "),
            "We used the ",
            tags$a(href = "https://ellmer.tidyverse.org/", "ellmer package", target = "_blank"),
            " to create connections to various models and the ",
            tags$a(href = "https://vitals.tidyverse.org/", "vitals package", target = "_blank"),
            " to evaluate model performance."
          ),
          tags$li(
            strong("Dataset: "),
            "Models were tested on the ", code("are"), " dataset (", strong("A"), "n ",
            strong("R"), " ", strong("E"), "val), which contains challenging R coding problems ",
            "and their solutions."
          ),
          tags$li(
            strong("Scoring: "),
            "Each model's solution was scored by Claude 3.7 Sonnet as either Incorrect, ",
            "Partially Correct, or Correct."
          ),
          tags$li(
            strong("Evaluation runs: "),
            "Each model completed 3 runs (epochs) on the dataset to account for variability."
          )
        ),

        h4("How to Use This App"),
        tags$ul(
          tags$li("Use the sidebar to select which models you want to compare"),
          tags$li(strong("Performance tab: "), "View the distribution of correct, partially correct, and incorrect solutions"),
          tags$li(strong("Cost vs Performance tab: "), "Compare model accuracy against the actual cost incurred during evaluation"),
          tags$li(strong("Pricing Details tab: "), "Explore detailed pricing and token usage with sortable, searchable table")
        ),

        h4("Resources"),
        tags$ul(
          tags$li(
            tags$a(
              href = "https://posit.co/blog/r-llm-evaluation/",
              "Read the full blog post about R code generation",
              target = "_blank"
            )
          ),
          tags$li(
            tags$a(
              href = "https://posit.co/blog/python-llm-evaluation/",
              "Read about Python (Pandas) code generation evaluation",
              target = "_blank"
            )
          ),
          tags$li(
            tags$a(
              href = "https://github.com/skaltman/model-eval-r",
              "View the evaluation code on GitHub",
              target = "_blank"
            )
          )
        ),

        hr(),

        p(
          class = "text-muted small",
          "Note: Pricing reflects per-million-token costs and actual charges incurred during the evaluation. ",
          "Token usage can vary significantly between models, especially for reasoning models which typically ",
          "generate more output tokens."
        )
      ),
      NULL
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
        decimals = 0,
        use_seps = TRUE
      ) |>
      fmt_percent(
        columns = `% Correct`,
        decimals = 1
      ) |>
      cols_align(
        align = "left",
        columns = everything()
      ) |>
      tab_header(
        title = "Model Pricing and Performance Details",
        subtitle = "Sorted by percent correct (descending)"
      ) |>
      data_color(
        columns = `% Correct`,
        palette = c("#ef8a62", "#f6e8c3", "#6caea7"),
        domain = NULL
      ) |>
      data_color(
        columns = `Total Cost`,
        palette = c("#e8f4f8", "#a8d5e2", "#6baed6", "#3182bd", "#08519c"),
        domain = NULL
      ) |>
      tab_options(
        table.font.size = px(14),
        heading.title.font.size = px(18),
        heading.subtitle.font.size = px(14),
        column_labels.font.weight = "bold",
        ihtml.use_pagination = FALSE,
        ihtml.use_page_size_select = FALSE,
        table.width = pct(100)
      )
  })
}

# ============================================================================
# Run App
# ============================================================================

shinyApp(ui = ui, server = server)
