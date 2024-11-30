# Notes on deploying ABFE_Workflow in LUMI environment (WIP)
ABFE workflow is cloned from the [GitHub repository](https://github.com/bigginlab/ABFE_workflow) as below:

```bash
# Login to LUMI  supercomputer and clone the repo
# ssh -i ~/.ssh/private_key <cscusername>@lumi.csc.fi  
mkdir -p /scratch/project_xxxx/$USER && cd /scartch/project_xxxx/$USER
git clone https://github.com/bigginlab/ABFE_workflow.git
```
## Approach 1 - Use [LUMI container wrapper](https://docs.lumi-supercomputer.eu/software/installing/container-wrapper/) 

### Intalling ABFE_Workflow environment in LUMI 

As `ABFE-Workflow` is available as a pip package, add it to the list of other pip packages in the environmet file `environment.yml` which is available in orginal ABFE GitHub repository. Otherwise install it from the cloned version.

Install ABFE_Workflow using container wrapper as below:
```bash
cd /scartch/project_xxxx/$USER/ABFE_workflow
module  purge
module load LUMI
module load lumi-container-wrapper
mkdir -p /projappl/project_xxx/ABFE_workflow
conda-containerize new --prefix  /projappl/project_xxx/ABFE_workflow  environment.yml

export PATH="/projappl/project_462000007/ABFE_workflow/bin:$PATH"
export PYTHONUSERBASE="/scratch/project_462000007/$USERABFE_workflow/venv"
export WORKDIR="/scartch/project_xxxx/$USER/ABFE_workflow"
pip3 install --user  .
pip3 install --user MDAnalysis==2.8.0
# Do some hacks to prevent errors from python interpreter
sed -i 's@#!.*@#!/projappl/project_462000007/ABFE_workflow/bin/python@g' /projappl/project_462000007/ABFE_workflow/bin/snakemake
ls $WORKDIR/venv/bin/* | xargs sed -i 's@#!.*@#!/projappl/project_462000007/ABFE_workflow/bin/python@g'
```
!! Note: In order to prevent errors related to Tpx format errors, change supperted version from 133 to 134 as expected from Gromacs v2024.3 ( go to line starting with "SUPPORTED_VERSIONS" in the script here : venv/lib/python3.10/site-packages/MDAnalysis/topology/tpr/setting.py and change 133 to 134 in the list of supported version) ..yes cheating !!!


### Running ABFE_Workflow 

```bash
# add installed binaries to $PATH 
export PATH="/projappl/project_xxx/ABFE_workflow/bin:$PATH"
# check if ABFE workflow is installed properly
cli-abfe -h
# check if toy example can be run
WORKDIR="/scratch/project_xxxx/$USER/ABFE_workflow"
mkdir -p ${WORKDIR}/Results
cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  \
 -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands \
 -o ${WORKDIR}/Results  \
-nogpu \
-nohybrid \
-nc 2 \     #   nc: NUMBER_OF_CPUS_PER_JOB
-nosubmit
```
Similarly you can also test for the command: cli-abfe-gmx 

As per cli-abfe-gmx command on LUMI,  gmx-mpi is the compiled binary at the moment on LUMI whereas ABFE workflow expects *gmx* command.   You can copy/rename and add the path. Here is an ad-hoc tweak ( this can be streamlined as needed later):

```bash
cp /appl/local/csc/soft/chem/gromacs/2024.4-gpu/bin/gmx_mpi . && mv gmx_mpi gmx
# as example is with toy data, one can run on login node 
export PATH="$PWD:$PATH"
cli-abfe-gmx -d  ${WORKDIR}/examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr 30 -nr 3  -nosubmit
```
  
For any **real-world** use case, wrap the same commands inside of batch script and submit it to the cluster:

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
mkdir -p ${WORKDIR}/Results
cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  \
 -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands \
 -o ${WORKDIR}/Results  \
 -nogpu \
 -nohybrid \
 -nc $SLURM_CPUS_PER_TASK \
 -nosubmit
```
Save above script to a file (say abfe_batch.sh) and submit the job to cluster after replacing with project name etc:
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
#cli-abfe-gmx command
mkdir -p ${WORKDIR}/abfe_HSP90_out
export PATH="$PWD:$PATH"
cli-abfe-gmx -d  ${WORKDIR}/examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr $SLURM_CPUS_PER_TASK -nr 3  -nosubmit
```

## Approach 2 - Use Singularity/Apptainer container 

### Build a Singularity image with ABFE workflow environment
```bash
# Build a singularity container image for ABFE_workflow environment
singularity --fakeroot abfe.sif abfe.def  # Image is built on Puhti and it can be downloaded: wget  https://a3s.fi/abfe/abfe.sif
```
The abfe.def file is below:

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

### Run the ABFE_Workflow

Run ABFE_workflow inside of a container 

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

WORKDIR="/scratch/project_xxxx/$USER/ABFE_workflow"
#cli-abfe command
singularity exec -B $PWD abfe.sif cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands -o ${WORKDIR}/Results  -nogpu -nohybrid -nc $SLURM_CPUS_PER_TASK  -nosubmit

```
Run ABFE_GMX workflow inside of a container 

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

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# cli-abfe-gmx command
export PATH="$PWD:$PATH"
singularity exec -B $PWD abfe.sif cli-abfe-gmx -d  examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr $SLURM_CPUS_PER_TASK -nr 3  -nosubmit

```
