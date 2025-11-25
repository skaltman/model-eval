## Overview

This app displays evaluation results comparing how well various Large Language Models (LLMs) generate R code. With many AI coding assistants available, this evaluation helps you choose the best model for R programming tasks.

## Methodology

- **Framework:** We used the [ellmer package](https://ellmer.tidyverse.org/) to create connections to various models and the [vitals package](https://vitals.tidyverse.org/) to evaluate model performance.

- **Dataset:** Models were tested on the `are` dataset (**A**n **R** **E**val), which contains challenging R coding problems and their solutions.

- **Scoring:** Each model's solution was scored by Claude 3.7 Sonnet as either Incorrect, Partially Correct, or Correct.

- **Evaluation runs:** Each model completed 3 runs (epochs) on the dataset to account for variability.

## How to Use This App

- Use the sidebar to select which models you want to compare
- **Performance tab:** View the distribution of correct, partially correct, and incorrect solutions
- **Cost vs Performance tab:** Compare model accuracy against the actual cost incurred during evaluation
- **Pricing Details tab:** Explore detailed pricing and token usage with sortable, searchable table

## Resources

- [Read the full blog post about R code generation](https://posit.co/blog/r-llm-evaluation/)
- [Read about Python (Pandas) code generation evaluation](https://posit.co/blog/python-llm-evaluation/)
- [View the evaluation code on GitHub](https://github.com/skaltman/model-eval-r)

---

*Note: Pricing reflects per-million-token costs and actual charges incurred during the evaluation. Token usage can vary significantly between models, especially for reasoning models which typically generate more output tokens.*
