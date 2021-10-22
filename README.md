# gromacs-notebook (WIP)
Porting gromacs-notebook in CSC environment


## Building singularity image of gromacs-notebook  for Puhti usage

```bash
# Build docker images locally using dockerfile, gromacs-notebook.dockerfile
sudo docker build -t gmxapi/notebook:puhti -f gromacs-notebook.dockerfile . 

# Push to local registry
sudo docker tag gmxapi/notebook:puhti localhost:5000/gmxapi-notebook:puhti
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
sudo docker push localhost:5000/gmxapi-notebook:puhti

# Build singularity image from deffile

sudo SINGULARITY_NOHTTPS=1 singularity build gromacs-notebook-puhti.sif gromacs-notebook.deffile 

# or simply

sudo SINGULARITY_NOHTTPS=1 singularity build  gromacs-notebook-puhti.sif  docker://localhost:5000/gmxapi-notebook:puhti
```

## Deploying gromacs-notebook on Puhti in home directory (just for testing, NOT for production)

Download singularity image from allas object storage

```bash
wget https://a3s.fi/Gromacs_utilities/gromacs.tar.gz
tar -xavf gromacs.tar.gz 
cd gromacs
```
Port rendering on Puhti

Issue the following SSH command on local machine:
```bash
ssh -l <username> -L 8888:localhost:8888 puhti-login1.csc.fi    # change port number if notebook is exposed on different port (default port is 8888 here); 
                                                                # choose login1 or login2 node depending on where notebook is launched
```
Launch gromacs-notebook

```bash
singularity exec -B /users/<username>  gromacs-notebook-puhti.sif /docker_entry_points/notebook

```
Point your browser to http://localhost:8888  on your local machine and the copy the token value generated after launching notebook. or simply, copy and paste full path (i.e., http://localhost:8888/?token=tokenkey). If successful, gromacs-notebook should appear in browser.

### Deploying gromacs-notebook on Puhti as an interactive job (Production)

Download singularity image from allas object storage as before

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs.tar.gz
tar -xavf gromacs.tar.gz 
cd gromacs
```

Launch gromacs-notebook in an interactive node

Lanuch interactive session as below:

```bash
# start interactive node as below and choose your project name on prompt
sinteractive -c 2 -m 4G -d 250

# Launch notebook

singularity exec -B /users/<username>  gromacs-notebook-puhti.sif /docker_entry_points/notebook # mount your home to work
```
SSH port tunneling for login node first and then for compute node

```bash
ssh -l <username> -L 8888:localhost:8888 puhti-login1.csc.fi    # Issue this command while being on local machine
                                                                # change port number if notebook is exposed on different port (default port is 8888 here); 
                                                                # choose login1 or login2 node depending on where notebook is launched
                                                                                                                       
ssh -l <username>  -L 8888:localhost:8888 <username>@$HOSTNAME      # Issue this command on login node; $HOSTNAME is compute node attached to interactive session
                                                                
```

Point your browser to http://localhost:8888  and copy the token value generated after launching notebook. or copy and paste full path (i.e., http://localhost:8888/?token=tokenkey). If successful, gromacs-notebook should be visible.


### Deploying gromacs-notebook on Puhti as a batch job (Production)

Download singularity image from allas object storage as before

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs.tar.gz
tar -xavf gromacs.tar.gz 
cd gromacs
```

Lanuch  batch job as below:

```bash
#!/bin/bash
#SBATCH --time=00:15:00
#SBATCH --partition=test
#SBATCH --account=project_xxx

echo $HOSTNAME

singularity exec -B /users/$USER  gromacs-notebook-puhti.sif /docker_entry_points/notebook
```
SSH port tunneling for login node first and then for compute node

```bash
ssh -l <username> -L 8888:localhost:8888 puhti-login1.csc.fi    # Issue this command while being on local machine
                                                                # change port number if notebook is exposed on different port (default port is 8888 here); 
                                                                # choose login1 or login2 node depending on where notebook is launched
                                                                                                                       
ssh -l <username>  -L 8888:localhost:8888 <username>@$HOSTNAME       # Issue this command on login node; $HOSTNAME is compute node attached in batch job
                                                                     # hostname  of compute node attached to batch job is available in slurm output file 
                                                                
```

Point your browser to http://localhost:8888  and copy the token value generated after launching notebook. or copy and paste full path (i.e., http://localhost:8888/?token=tokenkey). If successful, gromacs-notebook should be visible.



