#!/usr/bin/env nextflow

// Specify DSL2
nextflow.enable.dsl=2

// This module uses the Dfam consortium's very handy container.
// See https://github.com/Dfam-consortium/TETools/ for how to add
// custom databases to the container.

// Process definition
process repeatmodeler_database {
    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy",
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container "dfam/tetools:1.2"
    containerOptions '-u \$(id -u):\$(id -g) -v "$PWD":/work --env "HOME=/work"'

    input:
        val opts
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("*{nhr,nin,nnd,nni,nog,nsq,translation}"), emit: repeatmodeler_db

    script:

    args = ""
    if(opts.args) {
        ext_args = opts.args
        args += ext_args.trim()
    }

    repeatmodeler_database_command = "BuildDatabase $args -name ${fasta.simpleName} ${fasta}"

    if (params.verbose){
        println ("[MODULE] repeatmodeler_database_command command: " + repeatmodeler_database_command)
    }

    //SHELL
    """
    ${repeatmodeler_database_command}
    """
}

process repeatmodeler_model {
    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy",
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container "dfam/tetools:1.2"
    containerOptions '-u \$(id -u):\$(id -g) -v "$PWD":/work --env "HOME=/work"'

    input:
        val opts
        tuple val(meta), path(fasta)
        tuple val(meta), path(repeatmodeler_db)

    output:
        tuple val(meta), path("*"), emit: repeatmodeler

    script:

    args = ""
    if(opts.args) {
        ext_args = opts.args
        args += ext_args.trim()
    }

    repeatmodeler_model_command = "RepeatModeler $args -srand ${opts.rng_seed} -database ${fasta.simpleName}"

    if (params.verbose){
        println ("[MODULE] repeatmodeler_model command: " + repeatmodeler_model_command)
    }

    //SHELL
    """
    ${repeatmodeler_model_command}
    """
}


process repeatmasker {
    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${opts.publish_dir}",
        mode: "copy",
        overwrite: true,
        saveAs: { filename ->
                      if (opts.publish_results == "none") null
                      else filename }

    container "dfam/tetools:1.2"
    containerOptions '-u \$(id -u):\$(id -g) -v "$PWD":/work --env "HOME=/work"'

    input:
        val opts
        tuple val(meta), path(fasta)
        tuple val(meta), path(repeatmodeler_db)

    output:
        tuple val(meta), path("*"), emit: repeatmodeler

    script:

    args = ""
    if(opts.args) {
        ext_args = opts.args
        args += ext_args.trim()
    }

    repeatmodeler_model_command = "RepeatMaster $args -e ${opts.engine} -pa ${opts.pa} "

    if (params.verbose){
        println ("[MODULE] repeatmodeler_model command: " + repeatmodeler_model_command)
    }

    //SHELL
    """
    ${repeatmodeler_model_command}
    """
}