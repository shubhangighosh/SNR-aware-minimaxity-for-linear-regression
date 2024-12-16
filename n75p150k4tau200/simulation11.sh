#!/bin/sh
#simulation11.sh
#
#SBATCH -A stats              # Replace ACCOUNT with your group account name 
#SBATCH -J sparse11    # The job name
#SBATCH -c 28                   # The number of cpu cores to use. Max 32.
#SBATCH -t 0-24:30                # Runtime in D-HH:MM
#SBATCH --mem-per-cpu 5gb        # The memory the job will use per cpu core

module load R

#Command to execute R code
R CMD BATCH --no-save --vanilla '--args params11.txt' ../simulations_bss.R simulations11.out
