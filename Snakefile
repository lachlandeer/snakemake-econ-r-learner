## Snakemake - MRW Replication
##
## @yourname

# --- Dictionaries --- #
# Identify subset conditions for data
DATA_SUBSET = glob_wildcards("src/data-specs/{fname}.json").fname
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))

# Models we want to estimate
MODELS = glob_wildcards("src/model-specs/{fname}.json").fname

FIGURES = glob_wildcards("src/figures/{fname}.R").fname

# --- Build Rules --- #

rule all:
    input:
        figs   = expand("out/figures/{iFigure}.pdf",
                            iFigure = FIGURES),
        models = expand("out/analysis/{iModel}_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET)

rule make_figs:
    input:
        expand("out/figures/{iFigure}.pdf",
                iFigure = FIGURES)

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

rule estimate_models:
    input:
        expand("out/analysis/{iModel}_{iSubset}.rds",
                    iModel = MODELS,
                    iSubset = DATA_SUBSET)

rule ols_model:
    input:
        script = "src/analysis/estimate_ols_model.R",
        data   = "out/data/mrw_complete.csv",
        model  = "src/model-specs/{iModel}.json",
        subset = "src/data-specs/subset_{iSubset}.json"
    output:
        model_est = "out/analysis/{iModel}_{iSubset}.rds",
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.model_est}"

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
rule clean:
    shell:
        "rm -rf out/*"
