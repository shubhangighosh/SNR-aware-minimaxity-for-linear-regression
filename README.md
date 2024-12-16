# SNR-aware minimaxity for linear regression
Usage:
1. Navigate to folder according to sample size (n), dimension (p), and sparsity level (k) requirements. For example, for n=500, p=500, k=35, go to n500p500k35tau200. Here tau is the signal strength and has been set to 200.
2. Create a ``params.txt`` file specifying the noise standard deviation, and hyperparameters for different estimators. You may find example ``params`` files in the folder.
3. To run simulations without including the best-subset selection estimator, run ``R ../simulations.R params.txt``. To include the best-subset selection estimator, run ``R ../simulations_bss.R params.txt``.
4. In each folder, you may run ``./run_all_here.sh`` or ``./run_parallel.sh`` if you are using a SLURM based workflow to generate the MSE and standard errors for a set of specified standard deviations.
5. To plot the performance, use the python notebook ``plots.ipynb``.
