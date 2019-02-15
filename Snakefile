## Snakemake - MRW Replication
##
## @yourname
##

from pathlib import Path

# --- Importing Configuration Files --- #

configfile: "config.yaml"

# --- Dictionaries --- #
# Identify subset conditions for data
DATA_SUBSET = glob_wildcards(config["src_data_specs"] +
                                    "{fname}.json").fname
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))

# Models we want to estimate
MODELS = glob_wildcards(config["src_model_specs"] +
                                "{fname}.json").fname

FIGURES = glob_wildcards(config["src_figures"] +
                                "{fname}.R").fname
TABLES  = [
            "tab01_textbook_solow",
            "tab02_augment_solow"
]

# --- Sub Workflows --- #
subworkflow tables:
   workdir: config["ROOT"]
   snakefile: config["src_tables"] + "Snakefile"

subworkflow analysis:
   workdir: config["ROOT"]
   snakefile: config["src_analysis"] + "Snakefile"

subworkflow figs:
   workdir: config["ROOT"]
   snakefile: config["src_figures"] + "Snakefile"

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
        tables  = tables(expand(config["out_tables"] +
                            "{iTable}.tex",
                            iTable = TABLES)
                            )

# --- Packrat Rules --- #

## packrat_install: installs packrat onto machine
# rule packrat_install:
#     shell:
#         "R -e 'install.packages(\"packrat\", repos=\"http://cran.us.r-project.org\")'"
rule packrat_install:
    input:
        script = config["src_lib"] + "install_packrat.R"
    log:
        config["log"] + "packrat/install_packrat.Rout"
    shell:
        "Rscript {input.script} > {log} 2>&1"


## packrat_init: initialize a packrat environment for this project
rule packrat_init:
    input:
        script = config["src_lib"] + "init_packrat.R"
    log:
        config["log"] + "packrat/init_packrat.Rout"
    shell:
        "Rscript {input.script} > {log} 2>&1"

## packrat_snap   : Look for new R packages in files & archives them
rule packrat_snap:
    shell:
        "R -e 'packrat::snapshot()'"

## packrat_restore: Installs archived packages onto a new machine
rule packrat_restore:
    shell:
        "R -e 'packrat::restore()'"

# --- Clean Rules --- #
## clean              : removes all content from out/ directory
rule clean:
    shell:
        "rm -rf out/*"

# --- Help Rules --- #
## help               : prints help comments for Snakefile
rule help:
    input:
        main     = "Snakefile",
        tables   = config["src_tables"] + "Snakefile",
        analysis = config["src_analysis"] + "Snakefile",
        data_mgt = config["src_data_mgt"] + "Snakefile",
        figs     = config["src_figures"] + "Snakefile"
    output: "HELP.txt"
    shell:
        "find . -type f -name 'Snakefile' | tac | xargs sed -n 's/^##//p' \
            > {output}"
