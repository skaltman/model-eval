#!/usr/bin/env bash
set -euo pipefail

# An array of model IDs and labels
declare -A MODELS=(
  # [gpt_o1]="openai/o1-2024-12-17"
  [gpt_o3_mini]="openai/o3-mini-2025-01-31"
  # [gpt_o3]="openai/o3-2025-04-16"
  # [o4_mini]="openai/o4-mini-2025-04-16"
  # [gpt_4_1]="openai/gpt-4.1-2025-04-14"
  # [claude_sonnet_4]="anthropic/claude-sonnet-4-20250514"
)

# Location of your task file
TASK_FILE="eval.py"
TASK_NAME="ds_pandas_task"

# Loop over each model and run inspect eval
