This app displays evaluation results comparing how well various LLMs generate R code.

## Methodology

- We used the [ellmer package](https://ellmer.tidyverse.org/) to create connections to various models and the [vitals package](https://vitals.tidyverse.org/) to evaluate model performance.

- Models were evaluated on the [`are` dataset](https://vitals.tidyverse.org/reference/are.html) (**A**n **R** **E**val), which contains challenging R coding problems and their solutions. `are` is included in the vitals package.

- Each model's solution was scored by Claude 3.7 Sonnet as either Incorrect, Partially Correct, or Correct.

## Model Configuration

The **default** configuration for each model reflects the provider's own API defaults. This is what you get "out of the box" without specifying any additional parameters, and is typically the provider's recommended starting point for most use cases.

We also test some models with **alternative** configurations (marked with a ⚙️ in the sidebar) to show how enabling or adjusting thinking/reasoning features affects performance.
