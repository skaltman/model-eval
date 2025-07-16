# Which AI model writes the best Pandas code?
Sara Altman, Simon Couch

**LLMs can now help you write Python code. There are many available
models, so which one should you pick?**

We looked at a handful of models and evaluated how well they each
generate Python code. To do so, we used
[Inspect](https://inspect.aisi.org.uk/), a Python framework for LLM
evaluation, and the [DS-1000
dataset](https://ukgovernmentbeis.github.io/inspect_evals/evals/coding/ds1000/),
a code generation benchmark for Python data science libraries. For this
evaluation, we limited DS-1000 to only the 291 coding problems that
involved Pandas.

## Current recommendation for Pandas: OpenAI o3-mini, o4-mini, or Claude Sonnet 4

![](blog_python_files/figure-commonmark/unnamed-chunk-2-1.png)

**For Pandas coding tasks, we recommend using OpenAI’s o4-mini or
o3-mini or Anthropic’s Claude Sonnet 4.** The top models all performed
very similarly, but their prices vary substantially. **o4-mini, o3-mini,
and Claude Sonnet 4 are substantially less expensive than Gemini 2.5
Pro, o1, and o3** (see plot below). For Pandas code generation, we
expect that the additional cost will not translate to proportionally
better results.

> [!NOTE]
>
> ### Reasoning vs. non-reasoning models
>
> *Thinking* or *reasoning* models are LLMs that attempt to solve tasks
> through structured, step-by-step processing rather than just
> pattern-matching.
>
> Most of the models we looked at here are reasoning models, or are
> capable of reasoning. The only models not designed for reasoning are
> GPT-4.1 and Claude Sonnet 4 with thinking disabled.

![](blog_python_files/figure-commonmark/unnamed-chunk-3-1.png)

> [!CAUTION]
>
> ### Take token usage into account
>
> A **token** is the fundamental unit of data that an LLM can process
> (for text processing, a token is approximately a word). Reasoning
> models, like o3-mini and o4-mini, often generate significantly more
> output tokens than non-reasoning models. So while some models are
> inexpensive per token, their actual cost can be higher than expected.
>
> For example, Gemini 2.5 Pro, which performed best in the evaluation,
> was the second most expensive model. Its per-token cost is only
> moderately high, but it used substantially more reasoning tokens than
> other models, bringing its token total usage to 1,797,682.

## Key insights

- **Most of the current frontier models perform similarly on the Pandas
  problems from DS-1000.**
- **OpenAI’s o4-mini and o3-mini perform similarly to the more expensive
  models (Gemini 2.5 Pro, o1, and o3).**
- **Claude Sonnet 4 performed similarly regardless of whether thinking
  was enabled.** This is similar to what we found for [R code
  generation](https://posit.co/blog/r-llm-evaluation/).

### Limitations

**DS-1000 is a commonly used dataset,** so it’s likely that the models
were exposed to some or all of these problems during training. This
means our results may be inflated compared to performance on more
realistic or complex Pandas tasks.

Because of this, **the exact accuracy numbers aren’t especially
meaningful.** Model-to-model comparisons are more informative than
absolute performance. Even those comparisons should be interpreted with
caution since DS-1000 is such a common benchmark. Ideally, we’d evaluate
models on an unseen test set, but building one (especially one as large
as DS-1000) is very time-consuming.

We [previously evaluated](https://posit.co/blog/r-llm-evaluation/) a
similar set of models on R coding tasks. That evaluation used a much
smaller and more challenging dataset (`are`, from the vitals package),
whereas the 291 DS-1000 Pandas problems are easier and likely appeared
in the training data for many models. **Because the evaluation datasets
differ so much in difficulty and familiarity, you shouldn’t compare
performance across the Python and [R
evaluations](https://posit.co/blog/r-llm-evaluation/). Instead, compare
models only within each evaluation.**

## Pricing

LLM pricing is typically provided per million tokens. Note that in our
analysis, Gemini 2.5 Pro, o1, o3, o3-mini, and o4-mini performed
similarly for Python code generation, but Gemini 2.5 Pro, o1, and o3 are
more expensive.

<div id="zbupkyulhg" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#zbupkyulhg table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#zbupkyulhg thead, #zbupkyulhg tbody, #zbupkyulhg tfoot, #zbupkyulhg tr, #zbupkyulhg td, #zbupkyulhg th {
  border-style: none;
}
&#10;#zbupkyulhg p {
  margin: 0;
  padding: 0;
}
&#10;#zbupkyulhg .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#zbupkyulhg .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#zbupkyulhg .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#zbupkyulhg .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#zbupkyulhg .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#zbupkyulhg .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#zbupkyulhg .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#zbupkyulhg .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#zbupkyulhg .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#zbupkyulhg .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#zbupkyulhg .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#zbupkyulhg .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#zbupkyulhg .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#zbupkyulhg .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#zbupkyulhg .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zbupkyulhg .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#zbupkyulhg .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#zbupkyulhg .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#zbupkyulhg .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zbupkyulhg .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#zbupkyulhg .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zbupkyulhg .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#zbupkyulhg .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zbupkyulhg .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#zbupkyulhg .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zbupkyulhg .gt_left {
  text-align: left;
}
&#10;#zbupkyulhg .gt_center {
  text-align: center;
}
&#10;#zbupkyulhg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#zbupkyulhg .gt_font_normal {
  font-weight: normal;
}
&#10;#zbupkyulhg .gt_font_bold {
  font-weight: bold;
}
&#10;#zbupkyulhg .gt_font_italic {
  font-style: italic;
}
&#10;#zbupkyulhg .gt_super {
  font-size: 65%;
}
&#10;#zbupkyulhg .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#zbupkyulhg .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#zbupkyulhg .gt_indent_1 {
  text-indent: 5px;
}
&#10;#zbupkyulhg .gt_indent_2 {
  text-indent: 10px;
}
&#10;#zbupkyulhg .gt_indent_3 {
  text-indent: 15px;
}
&#10;#zbupkyulhg .gt_indent_4 {
  text-indent: 20px;
}
&#10;#zbupkyulhg .gt_indent_5 {
  text-indent: 25px;
}
</style>

| Price per 1 million tokens |         |         |
|----------------------------|---------|---------|
| Name                       | Input   | Output  |
| Gemini 2.5 Pro             | \$1.25  | \$15.00 |
| o1                         | \$15.00 | \$60.00 |
| o3-mini                    | \$1.10  | \$4.40  |
| o3                         | \$10.00 | \$40.00 |
| o4-mini                    | \$1.10  | \$4.40  |
| Gemini 2.5 Flash           | \$0.30  | \$2.50  |
| Claude Sonnet 4            | \$3.00  | \$15.00 |
| GPT-4.1                    | \$2.00  | \$8.00  |

</div>

## What about other packages?

This evaluation focused only on Pandas problems. We excluded DS-1000
tasks that did not involve Pandas.

In future work, we plan to evaluate model performance on other common
Python data science libraries, including Polars. Anecdotally, we’ve
found that models struggle more with Polars code, and we’re interested
in testing this formally.

## Methodology

- We used [Inspect](https://inspect.aisi.org.uk/) to create connections
  to evaluate model performance on Pandas code generation tasks.
- We tested each model on a shared benchmark: the [DS-1000
  dataset](https://ukgovernmentbeis.github.io/inspect_evals/evals/coding/ds1000/).
  DS-1000 contains a collection of Python data science problems that
  involve various libraries, including Pandas, TensorFlow, and
  Matplotlib. To constrain our evaluation, we only included the 291
  Pandas problems present in the data.  
- Using Inspect, we had each model solve each Pandas problem. Then, we
  scored their solutions using a scoring model (Claude Sonnet 4). Each
  solution received a score of Incorrect, Partially Correct, or Correct.

You can see all the code used to evaluate the models
[here](https://github.com/skaltman/model-eval/eval.py). If you’d like to
learn more about LLM evaluation for code generation, see Simon Couch’s
series of [blog posts](https://www.simonpcouch.com/blog/) and the
[Inspect website](https://inspect.aisi.org.uk/).
