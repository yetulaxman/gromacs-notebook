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

#
