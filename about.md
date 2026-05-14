This app displays evaluation results comparing how well various LLMs generate R code.

## Methodology

- We used the [ellmer package](https://ellmer.tidyverse.org/) to create connections to various models and the [vitals package](https://vitals.tidyverse.org/) to evaluate model performance.

- Models were evaluated on the [`are` dataset](https://vitals.tidyverse.org/reference/are.html) (**A**n **R** **E**val), which contains challenging R coding problems and their solutions. `are` is included in the vitals package.

- Each model's solution was scored by Claude 4.6 Sonnet as either Incorrect, Partially Correct, or Correct.

- Costs for the open-weight models (Qwen, Gemma, GPT-OSS) are listed as $0. These models can be downloaded and run locally for free, but you may incur costs if using a hosted inference service. For this analysis, open-weight models were run via [OpenRouter](https://openrouter.ai/) and costs were as follows:
    - GPT-OSS-20B: $0.06
    - Gemma 4 26B-A4B: $0.02
    - Qwen 3.5-35B-A3B: $0.30
    - Qwen 3.6-35B-A3B: $0.34


