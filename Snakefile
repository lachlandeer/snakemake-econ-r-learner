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
subworkflow data_mgt:
   workdir: config["ROOT"]
   snakefile:  config["src_data_mgt"] + "Snakefile"

subworkflow analysis:
   workdir: config["ROOT"]
   snakefile:  config["src_analysis"] + "Snakefile"

subworkflow figs:
   workdir: config["ROOT"]
   snakefile:  config["src_figures"] + "Snakefile"

# --- Build Rules --- #

## all                : builds all final outputs
rule all:
    input:
        figs   = figs(expand(config["out_figures"] +
                            "{iFigure}.pdf",
                            iFigure = FIGURES)
                            ),
        models = analysis(expand(config["out_analysis"] +
                            "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET)
                            ),
        tables  = expand(config["out_tables"] + "{iTable}.tex",
                            iTable = TABLES)

## augment_solow      : construct a table of estimates for augmented solow model
rule augment_solow:
    input:
        script = config["src_tables"] + "tab02_augment_solow.R",
        models = analysis(expand(config["out_analysis"] +
                            "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET)
                            ),
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
        models = analysis(expand(config["out_analysis"] +
                            "{iModel}_ols_{iSubset}.rds",
                            iModel = MODELS,
                            iSubset = DATA_SUBSET)
                            ),
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
