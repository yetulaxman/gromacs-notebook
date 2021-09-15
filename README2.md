## Provisioning Gromacs-course (FEBS 2021 advanced course) in CSC environment (WIP)

Computational environment  for FEBS course at CSC supercomputer (Puhti) can be accessed using the following two approaches:

- [Method 1: Access VMD and Gromacs Jupyter notebook directly *via* Open OnDemand (OoD) tools](#Access-VMD-and-Gromacs-Jupyter-notebook-via-Open-OnDemand-OoD-tools)
- [Method 2: Access noVNC+VMD and Gromacs Jupyter notebook *via* SSH tunneling](#Access-VMD-and-Gromacs-Jupyter-notebook-via-SSH-tunneling) (A back-up solution to method 1)

### Access VMD and Gromacs Jupyter notebook *via* Open OnDemand (OoD) tools:

1. CSC will provide a URL for accessing course environment via OoD approach
2. Click the URL and login page will open for Puhti authentication (Users should have accepted Puhti service in myCSC page under a course ( or own) project) before using this service. Login page is as shown below:

<img src="./Puhti_login.png" width="80%">

3. Once login is successfull, select "Courses" on the top menu bar and then click "Gromacs course". Fill all the necessary information ( e.g., select your CSC project, partition (sinteractive or small), computing resources among others) and then click "Launch" 
4. Upon successful launching a job, you can see the following window: 

<img src="./course_envi.png" width="100%">

5. Click on "Connect to VNC" to launch GUI desktop to then VMD (see below picture) 
<img src="./vmd.png" width="100%">
7. Agian on OoD job page, click on "Connect to Jupyter" to launch Gromacs notebook.



### Access VMD and Gromacs Jupyter notebook *via* SSH tunneling:

#### Access VMD via noVNC  and Gromacs notebook as an interactive job

Download singularity image from allas object storage:

```bash

mkdir /scratch/project_xxxx/$USER
cd /scratch/project_xxxx/$USER

# Download singularity image from allas object storage
wget https://a3s.fi/Gromacs_utilities/gromacs-notebook-febs2021.sif

```

1. Lanuch interactive session as below:

```bash
# start interactive node as below and choose your project name on prompt

sinteractive -c 2 -m 4G -d 250

# Launch VMD and Gromacs notebook by copying the following command and pasting on Puhti terminal:


singularity run -B /users/$USER -B /run gromacs-notebook-febs2021.sif

```
Just follow the instructions that appear on the terminal when you launch above command.



**Note**: if you don't have SSH-keys in place,  setting-up of SSH port tunneling involves entering some random port numbers. The SSH command would look like the following:

```bash
ssh  -L NNNN:localhost:NNNN -L MMMM:localhost:MMMM CSCUSERNAME@puhti.csc.fi ssh -L NNNN:localhost:8888 -L MMMM:localhost:38947 CSCUSERNAME@hostname
```
Make sure to use a different portnumbers by each user to avoid port collision on login nodes.
 - set some random number for NNNN,  e.g., NNNN = 5000 + the number in your training account
 - set some random number for MMMM; e.g., MMMM = 6000 + the number in your training account
