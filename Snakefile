MODELS = glob_wildcards("src/model-specs/{fname}.json").fname 

# note this filter is only needed coz we are running an older version of the src files, will be updated soon
DATA_SUBSET = glob_wildcards("src/data-specs/{fname}.json").fname
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))

PLOTS = glob_wildcards("src/figures/{fname}.R").fname

##############################################
# OLS TARGET
##############################################

rule run_models:
    input:
        expand("out/analysis/{iModel}.{iSubset}.rds",
                    iSubset = DATA_SUBSET,
                    iModel = MODELS)

##############################################
# OLS RULES
##############################################

rule model:
    input:
        script = "src/analysis/estimate_ols_model.R",
        data   = "out/data/mrw_complete.csv",
        model  = "src/model-specs/{iModel}.json",
        subset = "src/data-specs/{iSubset}.json"
    output:
        estimate = "out/analysis/{iModel}.{iSubset}.rds"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.estimate}"

##############################################
# figs TARGET
##############################################

rule make_figures:
    input:
        expand("out/figures/{iFigure}.pdf",
                    iFigure = PLOTS)

##############################################
# MAKING FIGS
##############################################

rule figure:
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

##############################################
# DATA MANAGEMENT
##############################################

rule gen_regression_vars:
    input:
        script = "src/data-management/gen_reg_vars.R",
        data   = "out/data/mrw_renamed.csv",
        param  = "src/data-specs/param_solow.json"
    output:
        data   = "out/data/mrw_complete.csv"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --param {input.param} \
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



##############################################
# CLEANING RULES
##############################################

rule clean:
    shell:
        "rm -rf out/*"

rule clean_data:
    shell:
        "rm -rf out/data/*"

rule clean_analysis:
    shell:
        "rm -rf out/analysis/*"

##############################################
# MAKE GRAPHS
##############################################

## dag                : create the DAG as a pdf from the Snakefile
rule dag:
    input:
        "Snakefile"
    output:
        "dag.pdf"
    shell:
        "snakemake --dag | dot -Tpdf > {output}"

## filegraph          : create the file graph as pdf from the Snakefile 
##                     (i.e what files are used and produced per rule)
rule filegraph:
    input:
        "Snakefile"
    output:
        "filegraph.pdf"
    shell:
        "snakemake --filegraph | dot -Tpdf > {output}"

## rulegraph          : create the graph of how rules piece together 
rule rulegraph:
    input:
        "Snakefile"
    output:
        "rulegraph.pdf"
    shell:
        "snakemake --rulegraph | dot -Tpdf > {output}"

## rulegraph_to_png
rule rulegraph_to_png:
    input:
        "rulegraph.pdf"
    output:
        "assets/rulegraph.png"
    shell:
        "pdftoppm -png {input} > {output}"
