version 1.0

# index vcf file

workflow indexVcf {
    meta {
        author: "Mira Mastoras"
        email: "mmastora@ucsc.edu"
        description: "Index vcf"
    }
    call Index
    output {
        File outVcfTbi = Index.outVcfTbi
    }
}

task Index{
    input {
        File vcf

        String dockerImage = "kishwars/pepper_deepvariant:r0.8"
        Int memSizeGB = 4
        Int threadCount = 2
        Int diskSizeGB = 16
    }

    command <<<
        # exit when a command fails, fail with unset variables, print commands before execution
        set -eux -o pipefail
        set -o xtrace

        FILENAME=$(basename -- "~{vcf}")
        SUFFIX="${FILENAME##*.}"

        if ![[ "$SUFFIX" == "gz" ]] ; then
            bgzip -c ~{vcf} > ./$FILENAME.gz
            ID=./$FILENAME.gz
        else
            ID=$FILENAME
            ln -s ~{vcf} ./$ID
        fi
        tabix -p vcf ${ID}
    >>>
    output {
        File outVcfTbi = glob("*.tbi")[0]
    }
    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerImage
    }
}
