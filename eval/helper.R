library(ellmer)
library(vitals)

# Set results directory
results_dir <- here::here("results_rds")

are_task <- Task$new(
  dataset = are,
  solver = generate(),
  scorer = model_graded_qa(
    scorer_chat = scorer_chat,
    partial_credit = TRUE
  ),
  epochs = 3,
  name = "An R Eval"
)


model_eval <- function(
  model,
  filename = model,
  chat_fun,
  overwrite = TRUE,
  ...
) {
  model_path <- fs::path(results_dir, filename, ext = "rds")

  if (!overwrite & fs::file_exists(model_path)) {
    message(glue::glue("Skipping {model}: file already exists at {model_path}"))
    return(invisible(NULL))
  }

  chat <- chat_fun(model = model, ...)

  are_model <- are_task$clone()
  are_model$eval(solver_chat = chat)

  readr::write_rds(are_model, file = model_path)
}
