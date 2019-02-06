## Snakemake - MRW Replication
##
## @yourname
##

# --- Dictionaries --- #
# Identify subset conditions for data
DATA_SUBSET = glob_wildcards("src/data-specs/{fname}.json").fname
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))

# Models we want to estimate
MODELS = glob_wildcards("src/model-specs/{fname}.json").fname

FIGURES = glob_wildcards("src/figures/{fname}.R").fname
TABLES  = [
            "tab01_textbook_solow",
            "tab02_augment_solow"
]

# --- Build Rules --- #

## all                : builds all final outputs
rule all:
    input:
        figs   = expand("out/figures/{iFigure}.pdf",
                            iFigure = FIGURES),
        models = expand("out/analysis/{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
        tables  = expand("out/tables/{iTable}.tex",
                            iTable = TABLES)

## augment_solow      : construct a table of estimates for augmented solow model
rule augment_solow:
    input:
        script = "src/tables/tab02_augment_solow.R",
        models = expand("out/analysis/{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
    params:
        filepath   = "out/analysis/",
        model_expr = "model_aug_solow*.rds"
    output:
        table = "out/tables/tab02_augment_solow.tex",
    shell:
        "Rscript {input.script} \
            --filepath {params.filepath} \
            --models {params.model_expr} \
            --out {output.table}"

## textbook_solow     : construct a table of regression estimates for textbook solow model
rule textbook_solow:
    input:
        script = "src/tables/tab01_textbook_solow.R",
        models = expand("out/analysis/{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
    params:
        filepath   = "out/analysis/",
        model_expr = "model_solow*.rds"
    output:
        table = "out/tables/tab01_textbook_solow.tex"
    log:
        "logs/tables/tab01_textbook_solow.Rout"
    shell:
        "Rscript {input.script} \
            --filepath {params.filepath} \
            --models {params.model_expr} \
            --out {output.table} \
            >& {log}"

## make_figs          : builds all figures
rule make_figs:
    input:
        expand("out/figures/{iFigure}.pdf",
                iFigure = FIGURES)

## figures            : recipe for constructing a figure (cannot be called)
rule figures:
    input:
        script = "src/figures/{iFigure}.R",
        data   = "out/data/mrw_complete.csv",
        subset = "src/data-specs/subset_intermediate.json"
    output:
        fig = "out/figures/{iFigure}.pdf"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --subset {input.subset} \
            --out {output.fig}"

## estimate_models    : estimates all regressions
rule estimate_models:
    input:
        expand("out/analysis/{iModel}_ols_{iSubset}.rds",
                    iModel = MODELS,
                    iSubset = DATA_SUBSET)

## ols_models         : recipe for estimating a single regression (cannot be called)
rule ols_model:
    input:
        script = "src/analysis/estimate_ols_model.R",
        data   = "out/data/mrw_complete.csv",
        model  = "src/model-specs/{iModel}.json",
        subset = "src/data-specs/{iSubset}.json"
    output:
        model_est = "out/analysis/{iModel}_ols_{iSubset}.rds",
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.model_est}"

## gen_regression_vars: creates variables needed to estimate a regression
rule gen_regression_vars:
    input:
        script = "src/data-management/gen_reg_vars.R",
        data   = "out/data/mrw_renamed.csv",
        params = "src/data-specs/param_solow.json",
    output:
        data = "out/data/mrw_complete.csv"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --param {input.params} \
            --out {output.data}"

## rename_vars        : creates meaningful variable names
rule rename_vars:
    input:
        script = "src/data-management/rename_variables.R",
        data   = "src/data/mrw.dta"
    output:
        data = "out/data/mrw_renamed.csv"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --out {output.data}"

# --- Clean Rules --- #
## clean              : removes all content from out/ directory
rule clean:
    shell:
        "rm -rf out/*"

# --- Help Rules --- #
## help               : prints help comments for Snakefile
rule help:
    input: "Snakefile"
    shell:
        "sed -n 's/^##//p' {input}"
