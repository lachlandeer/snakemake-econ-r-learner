## Snakemake - MRW Replication
##
## @yourname
##

# --- Importing Configuration Files --- #

configfile: "config.yaml"

# --- Dictionaries --- #
# Identify subset conditions for data
DATA_SUBSET = glob_wildcards(config["src_data_specs"] + "{fname}.json").fname
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))

# Models we want to estimate
MODELS = glob_wildcards(config["src_model_specs"] + "{fname}.json").fname

FIGURES = glob_wildcards(config["src_figures"] + "{fname}.R").fname
TABLES  = [
            "tab01_textbook_solow",
            "tab02_augment_solow"
]

# --- Sub Workflows --- #
# only need the final outputs here
subworkflow data_mgt:
   workdir: config["ROOT"]
   snakefile:  config["src_data_mgt"] + "Snakefile"

# --- Build Rules --- #

## all                : builds all final outputs
rule all:
    input:
        figs   = expand(config["out_figures"] + "{iFigure}.pdf",
                            iFigure = FIGURES),
        models = expand(config["out_analysis"] + "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
        tables  = expand(config["out_tables"] + "{iTable}.tex",
                            iTable = TABLES)

## augment_solow      : construct a table of estimates for augmented solow model
rule augment_solow:
    input:
        script = config["src_tables"] + "tab02_augment_solow.R",
        models = expand(config["out_analysis"] + "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
    params:
        filepath   = config["out_analysis"],
        model_expr = "model_aug_solow*.rds"
    output:
        table = config["out_tables"] + "tab02_augment_solow.tex",
    log:
        config["log"] + "tables/tab02_augment_solow.Rout"
    shell:
        "Rscript {input.script} \
            --filepath {params.filepath} \
            --models {params.model_expr} \
            --out {output.table} \
            >& {log}"

## textbook_solow     : construct a table of regression estimates for textbook solow model
rule textbook_solow:
    input:
        script = config["src_tables"] + "tab01_textbook_solow.R",
        models = expand(config["out_analysis"] + "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET),
    params:
        filepath   = config["out_analysis"],
        model_expr = "model_solow*.rds"
    output:
        table = config["out_tables"] + "tab01_textbook_solow.tex"
    log:
        config["log"] + "tables/tab01_textbook_solow.Rout"
    shell:
        "Rscript {input.script} \
            --filepath {params.filepath} \
            --models {params.model_expr} \
            --out {output.table} \
            >& {log}"

## make_figs          : builds all figures
rule make_figs:
    input:
        expand(config["out_figures"] + "{iFigure}.pdf",
                iFigure = FIGURES)

## figures            : recipe for constructing a figure (cannot be called)
rule figures:
    input:
        script = config["src_figures"] + "{iFigure}.R",
        data   = data_mgt(config["out_data"] + "mrw_complete.csv"),
        subset = config["src_data_specs"] + "subset_intermediate.json"
    output:
        fig = config["out_figures"] + "{iFigure}.pdf"
    log:
        config["log"]+ "figures/{iFigure}.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --subset {input.subset} \
            --out {output.fig} \
            >& {log}"

## estimate_models    : estimates all regressions
rule estimate_models:
    input:
        expand(config["out_analysis"] + "{iModel}_ols_{iSubset}.rds",
                    iModel = MODELS,
                    iSubset = DATA_SUBSET)

## ols_models         : recipe for estimating a single regression (cannot be called)
rule ols_model:
    input:
        script = config["src_analysis"] + "estimate_ols_model.R",
        data   = data_mgt(config["out_data"] + "mrw_complete.csv"),
        model  = config["src_model_specs"] + "{iModel}.json",
        subset = config["src_data_specs"]  + "{iSubset}.json"
    output:
        model_est = config["out_analysis"] + "{iModel}_ols_{iSubset}.rds",
    log:
        config["log"] + "analysis/{iModel}_ols_{iSubset}.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.model_est} \
            >& {log}"


# --- Clean Rules --- #
## clean              : removes all content from out/ directory
rule clean:
    shell:
        "rm -rf out/*"

# --- Help Rules --- #
## help               : prints help comments for Snakefile
rule help:
    input: "Snakefile"
    output: "HELP.txt"
    shell:
        "sed -n 's/^##//p' {input} > {output}"
