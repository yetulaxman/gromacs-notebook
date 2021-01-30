

## Deploying gromacs2021-notebook on Puhti as an interactive job 

### Download singularity image from allas object storage as below

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs_csc_2021.tar.gz
tar -xavf gromacs_csc_2021.tar.gz 
cd gromacs_2021
```

### Launch gromacs2021-notebook in an interactive node

Launch interactive session as below:

```bash
# start interactive node as below and choose your project name on prompt
sinteractive -c 2 -m 4G -d 250

# Launch notebook

singularity run -B /users/$USER  gromacs2021-notebook-cscpuhti.sif (for post-tunnel settings)
   
   or 
   
LOCAL_PORT=5007 singularity run -B /users/$USER  gromacs2021-notebook-cscpuhti.sif (for pre-tunnel settings using env variable, LOCAL_PORT)

```
Above command will start Jupyter server, and then it will print out instructions for a web address and a ssh command. Execute the ssh commands (copy-paste) as instructed to form a tunnel between your machine and the compute node.
 
