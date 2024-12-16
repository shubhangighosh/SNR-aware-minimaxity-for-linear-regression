#!/bin/bash

# Load necessary modules if required
module load R

# Specify your SLURM account name
account_name="stats"

# List of job scripts
job_scripts=("simulation1.sh" "simulation2.sh" "simulation3.sh" "simulation5.sh"
             "simulation6.sh" "simulation7.sh" "simulation8.sh"
             "simulation9.sh" "simulation10.sh" "simulation11.sh" "simulation12.sh"
             "simulation13.sh" "simulation14.sh" "simulation15.sh" "simulation16.sh"
             "simulation17.sh" "simulation18.sh")

# Number of parallel jobs per group
group_size=3

# Total number of scripts
total_scripts=${#job_scripts[@]}

# Loop through the job scripts in groups of `group_size`
for ((i=0; i<$total_scripts; i+=group_size)); do
    group_jobs=()
    
    # Submit each job in the current group
    for ((j=0; j<$group_size && i+j<$total_scripts; j++)); do
        script="${job_scripts[i+j]}"
        # Submit the job and capture its ID
        job_id=$(sbatch --account=$account_name "$script" | awk '{print $4}')
        group_jobs+=($job_id)
        echo "Submitted $script with Job ID: $job_id"
    done

    # Wait for all jobs in the current group to finish before starting the next group
    if [ ${#group_jobs[@]} -gt 0 ]; then
        # Generate a dependency string for the current group
        dependency_list=$(IFS=:; echo "${group_jobs[*]}")
        sbatch --account=$account_name --dependency=afterok:$dependency_list --wrap "echo 'Group $((i / group_size + 1)) completed'"
    fi
done

echo "All scripts have been submitted to SLURM!"
