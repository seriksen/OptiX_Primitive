# CUDA
export PATH=/usr/local/cuda-10.1/bin:/usr/local/cuda-10.1/NsightCompute-2019.3${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# NVidia OptiX
export LD_LIBRARY_PATH=/home/opc/OptiX/NVIDIA-OptiX-SDK-6.0.0-linux64/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export OPTIX_INSTALL_DIR=/home/opc/OptiX/NVIDIA-OptiX-SDK-6.0.0-linux64
export GPU_COMPUTE_CAPABILITY=60