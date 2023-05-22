version 1.0

workflow Clair3{

    call clair3

    output {
        File outVcf = clair3.clairVCF
        File outVcfIdx = clair3.clairVCFIDX
    }
}

task clair3 {
    input {
      File ref
      File refFai
      File bam
      File bai
      String platform = "ont"
      String modelName = "r941_prom_sup_g5014" # you can use guppy5 model for guppy6 according to their github

      Int threads = 64
      Int memSizeGb = 128
      Int diskSizeGb = 1024
      Int kmerSize = 17
      String dockerImage = "hkubal/clair3:latest"
    }


    command <<<
      set -o pipefail
      set -e
      set -u
      set -o xtrace

      ## Soft link fasta and index so they are in the same directory
      REF=$(basename ~{ref})
      REF_IDX=$(basename ~{refFai})

      ln -s ~{ref} ./$REF
      ln -s ~{refFai} ./$REF_IDX

      ## soft link bam and bai so they are in the same directory
      BAM=$(basename ~{bam})
      BAI=$(basename ~{bai})

      ln -s ~{bam} ./$BAM
      ln -s ~{bai} ./$BAI

      /opt/bin/run_clair3.sh --bam_fn=${BAM} --ref_fn=${REF} \
      --threads=~{threads} \
      --platform=~{platform} \
      --model_path="/opt/models/~{modelName}" \
      --output="./" \
      --include_all_ctgs

    >>>

    output {
      File clairVCF = "merge_output.vcf.gz"
      File clairVCFIDX = "merge_output.vcf.gz.tbi"
      }

    runtime {
      docker: dockerImage
      cpu: threads
      memory: memSizeGb + " GB"
      disks: "local-disk " + diskSizeGb + " SSD"
      preemptible: 2
    }
}
