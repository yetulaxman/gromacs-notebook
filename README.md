# Rough notes on deploying ABFE_Workflow in LUMI environment (WIP)
ABFE_workflow is cloned from the GitHub: https://github.com/bigginlab/ABFE_workflow

## Intalling ABFE_Workflow environment in LUMI 
```bash
# login to Puhti super computer  
mkdir /scratch/project_xxxx/$USER && cd /scartch/project_xxxx/$USER
git clone https://github.com/bigginlab/ABFE_workflow.git
cd ABFE_workflow
```
As `ABFE-Workflow` is available as pip package, add it to the list of pip packages in the file `environment.yml`

# Approach 1 - Use [LUMI container wrapper](https://docs.lumi-supercomputer.eu/software/installing/container-wrapper/) 

## Install ABFE_Workflow using container wrapper as below:
```bash
module  purge
module load LUMI
module load lumi-container-wrapper
mkdir -p /projappl/project_xxx/ABFE_workflow
conda-containerize new --prefix  /projappl/project_xxx/ABFE_workflow  environment.yml
```

## Run ABFE_Workflow as below:

````bash
# add installed binaries to $PATH 
export PATH="/projappl/project_xxx/ABFE_workflow/bin:$PATH"
# check if ABFE workflow is installed
cli-abfe -h
# check if toy example can be run
WORKDIR="/scratch/project_xxxx/$USER/ABFE_workflow"
cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  \
 -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands \
 -o ${WORKDIR}/Results  \
-nogpu \
-nohybrid \
-nc 2 \
-nosubmit

# cli-abfe-gmx code; gmx-mpi compiled binary at CSC; you can copy/rename and add the path. workflow uses `gmx`command. This set up can be changed  if needed 
cp /appl/local/csc/soft/chem/gromacs/2024.4-gpu/bin/gmx_mpi .
gmx_mpi gmx
# as example is with toy data, one can run on login node 
export PATH="$PWD:$PATH"
cli-abfe-gmx -d  ${WORKDIR}/examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr 30 -nr 3  -nosubmit
```
wrap the same job inside of batch script and submit it to the cluster:
```bash
#!/bin/bash -l
#SBATCH --job-name=examplejob   # Job name
#SBATCH --output=examplejob.o%j # Name of stdout output file
#SBATCH --error=examplejob.e%j  # Name of stderr error file
#SBATCH --partition=small       # Partition (queue) name
#SBATCH --ntasks=1              # One task (process)
#SBATCH --cpus-per-task=12     # Number of cores (threads)
#SBATCH --time=00:10:00         # Run time (hh:mm:ss)
#SBATCH --account=project_xxxx  # Project for billing

# Set the number of threads based on --cpus-per-task
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

export PATH="/projappl/project_xxxx /ABFE_workflow/bin:$PATH"
WORKDIR="/scratch/project_xxxx /$USER/ABFE_workflow"
#cli-abfe command

cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  \
 -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands \
 -o ${WORKDIR}/Results  \
 -nogpu \
 -nohybrid \
 -nc $SLURM_CPUS_PER_TASK \
 -nosubmit
```

submit the job to cluster:
```bash
sbatch abfe_batch.sh
```
Run cli-abfe-gmx on gpu node:
```bash
#!/bin/bash -l
#SBATCH --job-name=examplejob   # Job name
#SBATCH --output=examplejob.o%j # Name of stdout output file
#SBATCH --error=examplejob.e%j  # Name of stderr error file
#SBATCH --partition=small-g       # Partition (queue) name
#SBATCH --ntasks=1              # One task (process)
#SBATCH --cpus-per-task=12     # Number of cores (threads)
#SBATCH --time=00:10:00         # Run time (hh:mm:ss)
#SBATCH --account=project_xxxx # Project for billing

# Set the number of threads based on --cpus-per-task
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

export PATH="/projappl/project_xxxx/ABFE_workflow/bin:$PATH"
WORKDIR="/scratch/project_xxxxx/$USER/ABFE_workflow"
#cli-abfe command

export PATH="$PWD:$PATH"
cli-abfe-gmx -d  ${WORKDIR}/examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr $SLURM_CPUS_PER_TASK -nr 3  -nosubmit
```

# Approach 2 - Use Singularity/Apptainer container 

## Build a Singularity image with ABFE workflow environment
```bash
# Build a singularity container image for ABFE_workflow environment
singularity --fakeroot abfe.sif abfe.def  # this is ran on Puhti  and image can be downloaded: ```wget  https://a3s.fi/abfe/abfe.sif```
```
Where the content of abfe.def file is shown below:

```bash
Bootstrap : docker
From :  continuumio/miniconda3
IncludeCmd : yes

%labels
AUTHOR email@email.com

%files
environment.yml

%post
apt-get update && apt-get install -y procps && apt-get clean -y
/opt/conda/bin/conda env create -n snakemake_env -f /environment.yml
/opt/conda/bin/conda clean -a

%environment
export PATH=/opt/conda/bin:$PATH
. /opt/conda/etc/profile.d/conda.sh
conda activate snakemake_env

%runscript
echo "This is an example script for building singularity/appatainer image"
``` 

## Runnung ABFE_Workflow

## Run ABFE_workflow inside of a container 

```bash
#!/bin/bash -l
#SBATCH --job-name=examplejob   # Job name
#SBATCH --output=examplejob.o%j # Name of stdout output file
#SBATCH --error=examplejob.e%j  # Name of stderr error file
#SBATCH --partition=small       # Partition (queue) name
#SBATCH --ntasks=1              # One task (process)
#SBATCH --cpus-per-task=128     # Number of cores (threads)
#SBATCH --time=12:00:00         # Run time (hh:mm:ss)
#SBATCH --account=project_<id>  # Project for billing

WORKDIR="/scratch/project_xxxx/$USER/ABFE/ABFE_workflow"
#cli-abfe command
singularity exec -B $PWD abfe.sif cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands -o ${WORKDIR}/Results_gmx  -nogpu -nohybrid -nc 2  -nosubmit

```
#cli-abfe-gmx command

```bash
#!/bin/bash -l
#SBATCH --job-name=examplejob   # Job name
#SBATCH --output=examplejob.o%j # Name of stdout output file
#SBATCH --error=examplejob.e%j  # Name of stderr error file
#SBATCH --partition=small-g       # Partition (queue) name
#SBATCH --ntasks=1              # One task (process)
#SBATCH --cpus-per-task=128     # Number of cores (threads)
#SBATCH --time=12:00:00         # Run time (hh:mm:ss)
#SBATCH --account=project_<id>  # Project for billing

export PATH="$PWD:$PATH"
singularity exec -B $PWD abfe.sif cli-abfe-gmx -d  examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr 30 -nr 3  -nosubmit

```
