# Evals from 2025-11-01 on

library(ellmer)
library(vitals)
library(tidyverse)

SCORER_MODEL <- "claude-3-7-sonnet-latest"

# -------------------------------------------------------------------------------------------------------
vitals::vitals_log_dir_set(here::here("logs/02_eval"))
source(here::here("eval/helper.R"))

scorer_chat <- chat_anthropic(model = SCORER_MODEL)

# Gemini 3
model_eval(
  model = "gemini-3-pro-preview",
  filename = "gemini_3",
  chat_fun = chat_google_gemini
)

# GPT-5.1
model_eval(
  model = "gpt-5.1",
  filename = "gpt_5_1",
  chat_fun = chat_openai
)
