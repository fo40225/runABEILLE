# runABEILLE

`runABEILLE` is a convenient wrapper for [ABEILLE](https://github.com/UCA-MSI/ABEILLE) to simplify the execution process.

## Installation

### TL;DR

```bash
git clone https://github.com/fo40225/runABEILLE.git
cd runABEILLE
sudo docker build -t runABEILLE:0.0.1 .
```

If you don't have Docker, install Docker first:

https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run --rm hello-world
```

## Running

### Prepare Input Data

Input data should be in TSV files with the first line as the header, lines starting with # will be skipped, the first column representing transcripts' names, and the last column containing read counts.

Place TSV files into a folder and pass it as the input directory `inputDir`.

```bash
sudo docker -i -t --rm -v ${PWD}:${PWD} runABEILLE:0.0.1 Rscript /app/runABEILLE.R --inputDir ${PWD}/data --outputFile ${PWD}/result.tsv
```

### Hardware Optimization

#### Intel CPU with AVX512

```bash
sudo docker build -t runABEILLE:0.0.1 -f Dockerfile.intel_cpu_avx512 .
```

https://www.intel.com/content/www/us/en/developer/tools/oneapi/optimization-for-tensorflow.html

https://www.intel.com/content/www/us/en/developer/articles/guide/optimization-for-tensorflow-installation-guide.html

#### AMD CPU

```bash
sudo docker build -t runABEILLE:0.0.1 -f Dockerfile.amd_cpu .
```

https://blog.tensorflow.org/2023/03/enabling-optimal-inference-performance-on-amd-epyc-processors-with-the-zendnn-library.html

https://www.amd.com/en/developer/zendnn.html

#### NVIDIA GPU

- Install NVIDIA drivers first

https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-drivers
```

- Install NVIDIA-Docker

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && \
    sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi
```

- Build and run

```bash
sudo docker build -t runABEILLE:0.0.1 -f Dockerfile.nvidia_gpu .
sudo docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -i -t --rm -v ${PWD}:${PWD} runABEILLE:0.0.1 Rscript /app/runABEILLE.R --inputDir ${PWD}/data --outputFile ${PWD}/result.tsv
```

#### AMD GPU

- Install ROCm first

https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/native-install/ubuntu.html

- Build and run

```bash
sudo docker build -t runABEILLE:0.0.1 -f Dockerfile.amd_gpu .
sudo docker run --network=host --device=/dev/kfd --device=/dev/dri \
 --ipc=host --shm-size 16G --group-add video --cap-add=SYS_PTRACE \
 --security-opt seccomp=unconfined \
 -i -t --rm -v ${PWD}:${PWD} runABEILLE:0.0.1 Rscript /app/runABEILLE.R --inputDir ${PWD}/data --outputFile ${PWD}/result.tsv
```
