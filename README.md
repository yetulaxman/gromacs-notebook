# Notes on deploying ABFE_Workflow in LUMI environment (WIP)
ABFE workflow [GitHub repository](https://github.com/bigginlab/ABFE_workflow) is cloned and modified some hard-coded scripts from the workflow to fit to the slurm queues on LUMI. 

```bash
# Login to LUMI  supercomputer and clone the repo
# ssh -i ~/.ssh/private_key <cscusername>@lumi.csc.fi  
mkdir -p /scratch/project_xxxx/$USER && cd /scartch/project_xxxx/$USER
git clone https://github.com/yetulaxman/ABFE_workflow.git
```
## Use [LUMI container wrapper](https://docs.lumi-supercomputer.eu/software/installing/container-wrapper/) 

### Intalling ABFE_Workflow environment in LUMI supercomputer

Install ABFE_Workflow using container wrapper as below:
```bash
cd /scartch/project_xxxx/$USER/ABFE_workflow
module  purge
module load LUMI
module load lumi-container-wrapper
mkdir -p /projappl/project_xxx/ABFE_workflow
conda-containerize new --prefix  /projappl/project_xxx/ABFE_workflow  environment.yml

export PATH="/projappl/project_462000007/ABFE_workflow/bin:$PATH"
export PYTHONUSERBASE="/scratch/project_462000007/$USER/ABFE_workflow/venv"
export WORKDIR="/scratch/project_462000007/$USER/ABFE_workflow"
# install ABFE and MDanalysis as venv - you can modify the scripts as needed unlike those in tyykky env
pip3 install --user  .
pip3 install --user MDAnalysis==2.8.0
# Do some hacks to prevent errors from python interpreter
sed -i 's@#!.*@#!/projappl/project_462000007/ABFE_workflow/bin/python@g' /projappl/project_462000007/ABFE_workflow/bin/snakemake
ls $WORKDIR/venv/bin/* | xargs sed -i 's@#!.*@#!/projappl/project_462000007/ABFE_workflow/bin/python@g'
```
> In order to prevent errors Tpx format related errors, change supperted version from 133 to 134 in MDanalysis scripts as expected from Gromacs v2024.3 ( go to line starting with "SUPPORTED_VERSIONS" in the script here : venv/lib/python3.10/site-packages/MDAnalysis/topology/tpr/setting.py and change 133 to 134 in the list of supported version) ..yes cheating !!!

### Running ABFE_Workflow 

```bash
# add installed binaries to $PATH 
export PATH="/projappl/project_xxx/ABFE_workflow/bin:$PATH"
# check if ABFE workflow is installed properly
cli-abfe -h
# check if toy example can be run
WORKDIR="/scratch/project_462000007/$USER/ABFE_workflow"
export PATH="/projappl/project_462000007/ABFE_workflow/bin:$PATH"
export PYTHONUSERBASE="/scratch/project_462000007/$USER/ABFE_workflow/venv"
# just test with one ligand: ligand-4.sdf
mv ${WORKDIR}/examples/data/CyclophilinD_min/ligands ${WORKDIR}/examples/data/CyclophilinD_min/ligands_orig
mkdir ${WORKDIR}/examples/data/CyclophilinD_min/ligands && cp ${WORKDIR}/examples/data/CyclophilinD_min/ligands_orig/ligand-4.sdf  ${WORKDIR}/examples/data/CyclophilinD_min/ligands 
cli-abfe -p ${WORKDIR}/examples/data/CyclophilinD_min/receptor.pdb  -l ${WORKDIR}/examples/data/CyclophilinD_min/ligands -o ${WORKDIR}/Results -ncl 2  -njl 2  -njr 2 -nr 2
cd ${WORKDIR}/Results
wget https://a3s.fi/abfe/abfe_lumi.tar.gz && tar -xavf abfe_lumi.tar.gz && rm abfe_lumi.tar.gz
mv abfe_lumi/*.* .
bash prepare_for_lumi.sh

# Run jobs on LUMI using slurm exercutor (not recommended):
cd slurm_jobs
sbatch  lumi_batch_slurm_cpu.sh
sbatch  lumi_batch_slurm_gpu.sh
# Once above jobs are finished; collect the desired results
sbatch lumi_batch_slurm_final.sh 

# Run job on LUMI using HyperQueue executor
cd hq_jobs/
sbatch lumi_batch_hq_cpu.sh
sbatch lumi_batch_hq_gpu.sh
# finally collect results
sbatch lumi_batch_hq_final.sh
```

### Trouble shooting
