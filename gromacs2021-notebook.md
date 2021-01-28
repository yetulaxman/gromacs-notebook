

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

singularity run -B /users/$USER  gromacs2021-notebook-puhti.sif

```
Above command will start Jupyter server, and then it will print out instructions for a web address and a ssh command. Execute the ssh command (copy-paste) in another linux (or powershell) terminal  on your local machine to form a tunnel between your machine and the compute node.


### Open Jupyter url in  your local browser
Copy and paste full URL path (i.e., http://localhost:PORT/?token=tokenkey). If successful, gromacs-notebook should be visible in your local browser

 
