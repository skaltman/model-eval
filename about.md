## Overview

This app displays evaluation results comparing how well various LLMs generate R code. 

## Methodology

- We used the [ellmer package](https://ellmer.tidyverse.org/) to create connections to various models and the [vitals package](https://vitals.tidyverse.org/) to evaluate model performance.

- Models were evaluated on the `are` dataset (**A**n **R** **E**val), which contains challenging R coding problems and their solutions. `are` is included in the vitals package. 

- Each model's solution was scored by Claude 3.7 Sonnet as either Incorrect, Partially Correct, or Correct.

## Resources

- [Read the full blog post about R code generation](https://posit.co/blog/r-llm-evaluation-02/)
- [View the evaluation code on GitHub](https://github.com/skaltman/model-eval-r)
