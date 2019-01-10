## Snakemake - MRW Replication
##
## @yourname


# --- Build Rules --- #

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
