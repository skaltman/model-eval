# Model evals from 2025-05-01 - 2025-10-31

library(ellmer)
library(vitals)
library(tidyverse)

OPENAI_MODELS <-
  c(
    "gpt_o1" = "o1-2024-12-17",
    "gpt_o3_mini" = "o3-mini-2025-01-31",
    "gpt_o3" = "o3-2025-04-16",
    "gpt_o4_mini" = "o4-mini-2025-04-16",
    "gpt_4_1" = "gpt-4.1-2025-04-14",
    "gpt_5" = "gpt-5",
    "gpt_5_mini" = "gpt-5-mini",
    "gpt_5_nano" = "gpt-5-nano"
  )

ANTHROPIC_MODELS <-
  c(
    "claude-sonnet-4-20250514",
    "claude-sonnet-4-5-20250929",
    "claude-opus-4-1-20250805",
    "claude-haiku-4-5-20251001"
  ) |>
  set_names(
    \(x) str_remove(x, "-\\d{4}\\d{2}\\d{2}$") |> str_replace_all("-", "_")
  )

GEMINI_MODELS <-
  c("gemini_2_5_pro" = "gemini-2.5-pro")

SCORER_MODEL <- "claude-3-7-sonnet-latest"
# -------------------------------------------------------------------------------------------------------
vitals::vitals_log_dir_set("logs/01_eval")
source(here::here("scripts/helper.R"))

scorer_chat <- chat_anthropic(model = SCORER_MODEL)

iwalk(
  OPENAI_MODELS,
  model_eval,
  chat_fun = chat_openai,
  base_url = "https://api.openai.com/v1/responses"
)

# No thinking
model_eval(
  ANTHROPIC_MODELS,
  filename = "sonnet_4",
  chat_fun = chat_anthropic
)

# Thinking
iwalk(
  ANTHROPIC_MODELS[4] |> set_names(paste0, "_thinking"),
  model_eval,
  chat_fun = chat_anthropic,
  api_args = list(
    thinking = list(type = "enabled", budget_tokens = 2000)
  )
)

# Gemini
model_eval(
  GEMINI_MODELS,
  chat_fun = chat_google_gemini
)


# OpenAI OSS Models

# gpt-oss-20b
model_eval(
  model = "openai/gpt-oss-20b",
  file = "gpt_oss_20b",
  chat_fun = chat_openai,
  api_key = Sys.getenv("HUGGING_FACE_API_KEY"),
  base_url = "https://br0abwivakn2ibas.us-east-2.aws.endpoints.huggingface.cloud/v1"
)

# gpt-oss-120b
model_eval(
  model = "openai/gpt-oss-120b",
  file = "gpt_oss_120b",
  chat_fun = chat_openai,
  api_key = Sys.getenv("HUGGING_FACE_API_KEY"),
  base_url = "https://nd8rjz8obh824ny0.us-east-2.aws.endpoints.huggingface.cloud/v1"
)
