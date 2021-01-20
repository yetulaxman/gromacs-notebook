# gromacs-notebook
Porting gromacs-notebook in CSC environment


### Building singularity image of gromacs-notebook  for Puhti usage

```bash
# Build docker images locally using dockerfile, gromacs-notebook.dockerfile
sudo docker build -t gmxapi/notebook:puhti -f gromacs-notebook.dockerfile . 

# Push to local registry
sudo docker tag gmxapi/notebook:puhti localhost:5000/gmxapi-notebook:puhti
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
sudo docker push localhost:5000/gmxapi-notebook:puhti

# Build singularity image from deffile

sudo SINGULARITY_NOHTTPS=1 singularity build gromacs-notebook-puhti.sif deffile

```

### Deploying gromacs-notebook on Puhti

```bash

download singularity image from allas object storage


```

Open the port on Puhti

```bash

ssh -l yetukuri -L 8888:localhost:8888 puhti-login1.csc.fi  # change port number if notebook is exposed on different port (default port is 8888 here)
```
Launch gromacs-notebook

```bash
singularity exec -B /users/Puhti-username:/users/Puhti-username  gromacs.simg /docker_entry_points/notebook

```
Open browser http:localhost:8888
