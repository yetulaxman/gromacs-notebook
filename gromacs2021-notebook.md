## Building singularity image of gromacs-notebook  for Puhti usage

```bash
# Build docker images locally using dockerfile, gromacs-notebook.dockerfile
sudo docker build -t gmxapi2021/notebook:puhti -f gromacs-notebook.dockerfile . 

# Push to local registry
sudo docker tag gmxapi2021/notebook:puhti localhost:5000/gmxapi2021-notebook:puhti
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
sudo docker push localhost:5000/gmxapi2021-notebook:puhti

# Build singularity image from deffile

sudo SINGULARITY_NOHTTPS=1 singularity build gromacs2021-notebook-puhti.sif gromacs-notebook.deffile 

```


## Deploying gromacs2021-notebook on Puhti as an interactive job 

### Download singularity image from allas object storage as below

```bash
# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs_2021.tar.gz
tar -xavf gromacs_2021.tar.gz 
cd gromacs_2021
```

### Launch gromacs2021-notebook in an interactive node

Lanuch interactive session as below:

```bash
# start interactive node as below and choose your project name on prompt
sinteractive -c 2 -m 4G -d 250

# Launch notebook

singularity run -B /users/$USER:/home/tutorial/.local -B $PWD  gromacs2021-notebook-puhti.sif

```
Above command will start Jupyter server, and it will then print out a web address and a ssh command. Execute the ssh command (copy-paste) in another linux (or powershell) terminal  on your local machine to form a tunnel between your machine and the compute node.


### open url in browser on your local machine 
Copy and paste full URL path (i.e., http://localhost:PORT/?token=tokenkey). If successful, gromacs-notebook should be visible in your local browser

 
