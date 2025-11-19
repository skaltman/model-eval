# Evals from 2025-11-01 on

library(ellmer)
library(vitals)
library(tidyverse)

SCORER_MODEL <- "claude-3-7-sonnet-latest"

# -------------------------------------------------------------------------------------------------------
vitals::vitals_log_dir_set(here::here("logs/02_eval"))
source(here::here("scripts/helper.R"))

scorer_chat <- chat_anthropic(model = SCORER_MODEL)

model_eval(
  model = "gemini-3-pro-preview",
  filename = "gemini_3",
  chat_fun = chat_google_gemini
)
