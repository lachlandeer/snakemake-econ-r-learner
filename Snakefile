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
subworkflow paper:
   workdir: config["src_paper"]
   snakefile: config["src_paper"] + "Snakefile"

# --- Build Rules --- #

## all                : builds all final outputs
rule all:
    input:
        paper_pdf = paper(Path(config["sub2root"]) / config["out_paper"] / "paper.pdf")

rule install_windows:
    input:
        paper = rules.all.input.paper_pdf
    output:
        paper = "paper.pdf"
    shell:
        "powershell -Command Copy-Item {input.paper} -Destination {output.paper}"

# --- Packrat Rules --- #

## packrat_install: installs packrat onto machine
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
    input:
        script = config["src_lib"] + "snapshot_packrat.R"
    log:
        config["log"] + "packrat/snapshot_packrat.Rout"
    shell:
        "Rscript {input.script} > {log} 2>&1"

## packrat_restore: Installs archived packages onto a new machine
rule packrat_restore:
    input:
        script = config["src_lib"] + "restore_packrat.R"
    log:
        config["log"] + "packrat/restore_packrat.Rout"
    shell:
        "Rscript {input.script} > {log} 2>&1"

## install_rticles
rule install_rticles:
    input:
        script = config["src_lib"] + "install_rticles.R"
    log:
        config["log"] + "packrat/install_rticles.Rout"
    shell:
        "Rscript {input.script} > {log} 2>&1"

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
