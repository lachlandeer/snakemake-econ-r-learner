## Snakemake - MRW Replication
##
## @yourname

MODELS = [
          "model_solow",
          "model_solow_restr"
          ]

DATA_SUBSET = [
                "oecd",
                "intermediate",
                "nonoil"
                ]

# --- Build Rules --- #

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
