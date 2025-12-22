# `are` eval results Shiny app

library(shiny)
library(bslib)
library(bsicons)
library(gt)
library(purrr)

# Source plotting and data helper functions
source("R/helpers.R")

# Load Data ------------------------------------------------------------------

# Load pre-processed eval data
app_data <- readr::read_rds(here::here("data/data_combined.rds"))

are_eval_full <- app_data$eval_data
are_costs <- app_data$cost_data
model_info <- app_data$model_info

# Get available models
available_models <- get_available_models(are_eval_full)

# Add provider and configuration info
available_models_with_metadata <- available_models |>
  left_join(
    model_info |> select(model_join, provider, release_date, configuration, default_params_description),
    by = "model_join"
  ) |>
  arrange(provider, desc(release_date))

# Helper function to create display names for configurations
config_display_name <- function(config) {
  case_when(
    config == "default" ~ "Default",
    config == "thinking_1024" ~ "1024 thinking tokens",
    config == "reasoning_medium" ~ "Medium reasoning effort",
    TRUE ~ config  # Fallback to original name
  )
}

# Create grouped structure: for each base model (Name), list all configs
models_grouped <- available_models_with_metadata |>
  group_by(provider, model_display_base) |>
  summarise(
    configs = list(tibble(
      model_join = model_join,
      configuration = configuration,
      config_display = config_display_name(configuration),
      default_params_description = default_params_description
    )),
    has_alternatives = n() > 1,
    default_model_join = model_join[configuration == "default"][1],
    release_date = release_date[configuration == "default"][1],
    .groups = "drop"
  ) |>
  arrange(provider, desc(release_date))

# Models to select at startup (defaults only)
default_selected <- c(
  "opus_4_5",
  "sonnet_4_5",
  "haiku_4_5",
  "gemini_3",
  "gpt_5_1",
  "gpt_5"
)

# UI -------------------------------------------------------------------------

ui <- tagList(
  tags$head(
    tags$script(HTML("
      $(document).on('shown.bs.popover', function (e) {
        // Close all other popovers when a new one opens
        $('[data-bs-toggle=\"popover\"]').not(e.target).each(function() {
          var popover = bootstrap.Popover.getInstance(this);
          if (popover) {
            popover.hide();
          }
        });
      });
    "))
  ),
  page_navbar(
    title = "How well do LLMs generate R code?",
    id = "main_nav",

    nav_panel(
      "Results",
    page_sidebar(
      sidebar = sidebar(
        title = "Select models",
        width = 300,

        # Dynamic checkbox UI
        uiOutput("model_checkboxes"),

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
      ),

      navset_card_tab(
        nav_panel(
          "Performance",
          card(
            card_header("Score distribution by model"),
            card_body(
              plotOutput("performance_plot", height = "600px")
            )
          )
        ),

        nav_panel(
          "Cost vs. Performance",
          card(
            card_header("Compare accuracy and total cost"),
            card_body(
              plotOutput("cost_plot", height = "600px")
            )
          )
        ),

        nav_panel(
          "Pricing Details",
          card(
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
        h2("About this evaluation"),
        includeMarkdown("about.md")
      ),
      NULL
    )
  ),

  nav_spacer(),

  nav_item(
    tags$a(
      shiny::icon("github", style = "font-size: 1.5em;"),
      href = "https://github.com/skaltman/model-eval",
      target = "_blank"
    )
  )
  )
)

# Server ---------------------------------------------------------------------

server <- function(input, output, session) {
  # Track which configs are selected for each base model (can be multiple)
  # Structure: list where each element is a character vector of selected configs
  # Initialize only for models in default_selected
  initial_configs <- setNames(
    vector("list", nrow(models_grouped)),
    models_grouped$default_model_join
  )
  for (model_id in default_selected) {
    if (model_id %in% names(initial_configs)) {
      initial_configs[[model_id]] <- "default"
    }
  }

  selected_configs <- reactiveVal(initial_configs)

  # Render dynamic checkbox UI
  output$model_checkboxes <- renderUI({
    # Don't depend on selected_configs to avoid re-rendering popovers
    models_grouped |>
      group_split(provider) |>
      map(\(provider_df) {
        tagList(
          h6(
            unique(provider_df$provider),
            style = "margin-top: 10px; margin-bottom: 5px; color: #2c3e50; font-weight: 600;"
          ),
          div(
            style = "margin-top: -10px;",
            map(seq_len(nrow(provider_df)), \(i) {
              row <- provider_df[i, ]
              default_model_join <- row$default_model_join
              model_display_base <- row$model_display_base
              has_alternatives <- row$has_alternatives

              # Extract configs tibble from list-column (from a single row)
              configs_df <- row$configs[[1]]

              div(
                style = "margin-bottom: -10px; display: flex; align-items: center; gap: 5px;",
                div(
                  style = "flex-grow: 1;",
                  checkboxInput(
                    inputId = paste0("model_", default_model_join),
                    label = model_display_base,
                    value = default_model_join %in% default_selected,
                    width = "100%"
                  )
                ),
                if (has_alternatives) {
                  div(
                    style = "flex-shrink: 0; margin-top: -10px; color: #9ca3af; cursor: pointer;",
                    popover(
                      bsicons::bs_icon("gear", size = "0.9em"),
                      id = paste0("popover_", default_model_join),
                      title = "Configuration",
                      div(
                        style = "min-width: 250px;",
                        map(seq_len(nrow(configs_df)), \(j) {
                          config <- configs_df$configuration[j]
                          config_label <- configs_df$config_display[j]
                          default_desc <- configs_df$default_params_description[j]

                          # Only check if this model is in default_selected AND it's the default config
                          is_checked <- (default_model_join %in% default_selected) && (config == "default")

                          # Create styled label
                          if (config == "default" && !is.na(default_desc)) {
                            label_content <- tags$span(
                              style = "display: inline-block; line-height: 1.4;",
                              tags$div(style = "font-weight: 600; color: #2c3e50;", config_label),
                              tags$div(style = "font-size: 0.85em; color: #6c757d; margin-top: 2px;", default_desc)
                            )
                          } else if (config == "thinking_1024") {
                            label_content <- tags$span(
                              style = "display: inline-block; line-height: 1.4;",
                              tags$div(style = "font-weight: 600; color: #2c3e50;", "Extended thinking"),
                              tags$div(style = "font-size: 0.85em; color: #6c757d; margin-top: 2px;", "1024 thinking tokens")
                            )
                          } else {
                            label_content <- tags$span(
                              style = "font-weight: 600; color: #2c3e50;",
                              config_label
                            )
                          }

                          div(
                            style = "margin-bottom: 12px;",
                            checkboxInput(
                              inputId = paste0("config_", default_model_join, "_", config),
                              label = label_content,
                              value = is_checked
                            )
                          )
                        })
                      ),
                      placement = "right"
                    )
                  )
                }
              )
            })
          )
        )
      }) |>
      tagList()
  })

  # Handle config checkbox changes
  lapply(seq_len(nrow(models_grouped)), function(i) {
    model_join <- models_grouped$default_model_join[i]
    configs_df <- models_grouped$configs[[i]]  # This is already a tibble

    # Set up observers for each config checkbox
    lapply(configs_df$configuration, function(config) {
      element_id <- paste0("config_", model_join, "_", config)
      observeEvent(input[[element_id]], {
        # Collect all checked configs for this model
        checked_configs <- configs_df$configuration[
          sapply(configs_df$configuration, function(cfg) {
            isTRUE(input[[paste0("config_", model_join, "_", cfg)]])
          })
        ]

        # Update selected configs
        current_configs <- selected_configs()
        current_configs[[model_join]] <- checked_configs
        selected_configs(current_configs)

        # Auto-check the main model checkbox if any config is selected
        if (length(checked_configs) > 0) {
          updateCheckboxInput(
            session,
            inputId = paste0("model_", model_join),
            value = TRUE
          )
        } else {
          # Auto-uncheck if no configs are selected
          updateCheckboxInput(
            session,
            inputId = paste0("model_", model_join),
            value = FALSE
          )
        }
      }, ignoreInit = TRUE)
    })
  })

  # Reactive: Collect selected models from individual checkboxes
  selected_models <- reactive({
    configs_selected <- selected_configs()

    # For each checked base model, get all selected config variants
    models_grouped$default_model_join |>
      keep(\(base_model) {
        isTRUE(input[[paste0("model_", base_model)]])
      }) |>
      map(\(base_model) {
        # Get the selected configs for this model (can be multiple)
        selected_config_names <- configs_selected[[base_model]]

        # Default to "default" config if no configs selected
        if (is.null(selected_config_names) || length(selected_config_names) == 0) {
          selected_config_names <- "default"
        }

        # Find the model_joins for all selected configs
        idx <- which(models_grouped$default_model_join == base_model)
        configs_df <- models_grouped$configs[[idx]]  # Extract the tibble from the list-column

        # Return model_join for each selected config
        configs_df |>
          filter(configuration %in% selected_config_names) |>
          pull(model_join)
      }) |>
      flatten_chr()
  })

  # Reactive: Filtered evaluation data
  filtered_eval <- reactive({
    req(length(selected_models()) > 0)

    data <- are_eval_full |>
      filter(model_join %in% selected_models())

    # Calculate ordering based on correct answers
    model_order <- data |>
      mutate(model_display = as.character(model_display)) |>
      group_by(model_display) |>
      summarise(
        correct_count = sum(score == "Correct", na.rm = TRUE),
        .groups = "drop"
      ) |>
      arrange(correct_count) |>
      pull(model_display)

    # Set factor levels based on performance
    # Convert to character first to reset any existing factor levels
    data |>
      mutate(
        model_display = factor(as.character(model_display), levels = model_order)
      )
  })

  # Reactive: Summary statistics
  eval_summary <- reactive({
    req(length(selected_models()) > 0)

    compute_summary_stats(
      are_eval_full,
      are_costs,
      selected_models(),
      model_info
    )
  })

  # Select/Clear all buttons
  observeEvent(input$select_all, {
    # Select all models
    models_grouped$default_model_join |>
      walk(\(model_join) {
        updateCheckboxInput(
          session,
          inputId = paste0("model_", model_join),
          value = TRUE
        )
      })
  })

  observeEvent(input$clear_all, {
    # Clear all checkboxes
    models_grouped$default_model_join |>
      walk(\(model_join) {
        updateCheckboxInput(
          session,
          inputId = paste0("model_", model_join),
          value = FALSE
        )
      })
  })

  # Outputs ---------------------------------------------------------------------

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

    create_pricing_table(eval_summary(), model_info)
  })
}


shinyApp(ui = ui, server = server)
