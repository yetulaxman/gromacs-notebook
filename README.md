# gromacs-notebook (WIP)
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

### Deploying gromacs-notebook on Puhti in home directory (not for production)

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs.tar.gz
tar -xavf gromacs.tar.gz 
cd gromacs
```
Open the port on Puhti 

```bash
ssh -l csc-username -L 8888:localhost:8888 puhti-login1.csc.fi  # change port number if notebook is exposed on different port (default port is 8888 here); 
                                                                # choose login1 or login2 node depending on where notebook is launched
```
Launch gromacs-notebook

```bash
singularity exec -B /users/Puhti-username  gromacs-notebook-puhti.sif /docker_entry_points/notebook

```
Open browser at http://localhost:8888  on your local machine and the copy the token value generated after launching notebook. or simply, copy and paste full path (i.e., http://localhost:8888/?token=tokenkey). If successful, gromacs-notebook should appear in browser.

### Deploying gromacs-notebook on Puhti in interactive node 

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs.tar.gz
tar -xavf gromacs.tar.gz 
cd gromacs
```

### Launch gromacs-notebook in an interactive node
```bash
# start interactive node as below and choose the project on prompt
sinteractive -c 2 -m 4G -d 250

# launch notebook
```bash
singularity exec -B /users/csc-username  gromacs-notebook-puhti.sif /docker_entry_points/notebook # you have to mount your home to work
```
### ssh port tunneling for  login node first and then for compute node next

```bash
ssh -l csc-username -L 8888:localhost:8888 puhti-login1.csc.fi  # Do this command while being on local machine
                                                                # change port number if notebook is exposed on different port (default port is 8888 here); 
                                                                # choose login1 or login2 node depending on where notebook is launched
                                                                                                                       
ssh -l csc-username  -L 8888:localhost:8888 csc-username@r07c52  # where r07c52 is compute node
                                                                 # do thin on login node
```

Open browser http://localhost:8888  and copy the token value generated after launching notebook. or copy and paste full path (i.e., http://localhost:8888/?token=tokenkey). If successful, gromacs-notebook should be visible.
