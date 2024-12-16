#!/bin/bash

# Load necessary modules if required (uncomment the next line if needed)
module load R

# Submit each script using sbatch

job_scripts=("simulation1.sh" "simulation2.sh" "simulation3.sh" "simulation4.sh" "simulation5.sh" "simulation6.sh" "simulation7.sh" "simulation8.sh" "simulation9.sh" "simulation10.sh" "simulation11.sh" "simulation12.sh" "simulation13.sh" "simulation14.sh" "simulation15.sh" "simulation16.sh" "simulation17.sh" "simulation18.sh")

# Initialize a variable for the first job ID
previous_job_id=""

for script in "${job_scripts[@]}"; do
    if [ -z "$previous_job_id" ]; then
        # Submit the first job without any dependency
        job_id=$(sbatch "$script" | awk '{print $4}')
    else
        # Submit subsequent jobs with a dependency on the previous job
        job_id=$(sbatch --dependency=afterok:$previous_job_id "$script" | awk '{print $4}')
    fi

    # Update the previous job ID for the next iteration
    previous_job_id=$job_id

    echo "Submitted $script with Job ID: $job_id"
done


echo "All scripts have been submitted to SLURM!"