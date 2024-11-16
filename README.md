# ABFE_Workflow on LUMI (WIP)
Porting ABFE_Workflow in LUMI environment

## Intalling ABFE_Workflow environment using LUMI container wrapper
[LUMI container wrapper](https://docs.lumi-supercomputer.eu/software/installing/container-wrapper/) installs applications inside of a singularity container.


```bash
# login to Puhti super computer  
mkdir /scartch/project_xxxx/$USER && cd /scartch/project_xxxx/$USER
git clone https://github.com/bigginlab/ABFE_workflow.git
cd ABFE_workflow
```
add `ABFE-Workflow` package to the list of pip packages in the file `environment.yml`

# Aproach 1 - Use LUMI container wrapper 
## Installl ABFE using container wrapper
```bash
module  purge
module load LUMI
module load lumi-container-wrapper
mkdir -p /projappl/project_xxx/ABFE_workflow
conda-containerize new --prefix  /projappl/project_xxx/ABFE_workflow  environment.yml
```

## Runnung ABFE_Workflow 

````bash
# cli-abfe code 
export PATH="/projappl/project_xxx/ABFE_workflow/bin:$PATH"
WORKDIR="/scratch/project_xxxx/$USER/ABFE/ABFE_workflow"
cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands -o ${WORKDIR}/Results  -nogpu -nohybrid -nc 2  -nosubmit

# cli-abfe-gmx code 
cp /appl/local/csc/soft/chem/gromacs/2024.4-gpu/bin/gmx_mpi .
gmx_mpi gmx
export PATH="$PWD:$PATH"
cli-abfe-gmx -d  ${WORKDIR}/examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr 30 -nr 3  -nosubmit
```

# Approach 2 - Use Singularity/Apptainer container 

## Build a Singularity image with ABFE workflow environment
```bash
# Build a singularity container for ABFE_workflow environment
singularity --fakeroot abfe.sif abfe.def 
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

singularity exec -B $PWD abfe.sif cli-abfe-gmx -d  examples/data/HSP90_gmx -o abfe_HSP90_out -pn HSP90_gmx -njr 30 -nr 3  -nosubmit

```
