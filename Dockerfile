FROM nvidia/cuda:11.4.1-devel-ubuntu18.04

# Prevents apt-get to show interactive screen
ARG DEBIAN_FRONTEND=noninteractive

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		wget \
		neovim \
		tzdata \
		python3 \
		python3-dev \
		python3-pip \
		&& \
		apt-get clean && \
		rm -rf /var/lib/apt/lists/*

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV PATH /usr/local/cuda/bin:$PATH
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV LANG C.UTF-8

RUN pip3 --no-cache-dir install --upgrade \
	pip \
	setuptools

# Opencv prerequisite
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	cmake \
	pkg-config \
	libopencv-dev \
	# For still images
	libjpeg-dev \
	libtiff5-dev \
	#	libjasper-dev \
	libpng-dev \
	# For videos
	libavcodec-dev \
	libavformat-dev \
	libswscale-dev \
	libdc1394-22-dev \
	libxvidcore-dev \
	libx264-dev \
	x264 \
	libxine2-dev \
	libv4l-dev \
	v4l-utils \
	libgstreamer1.0-dev \
	libgstreamer-plugins-base1.0-dev \
	# GUI
	libgtk-3-dev \
	# Optimization, Python3
	libatlas-base-dev \
	libeigen3-dev \
	gfortran \
	python3-dev \
	python3-numpy \
	libtbb2 \
	libtbb-dev && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*


RUN cd && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
	bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
	rm Miniconda3-latest-Linux-x86_64.sh && \
	/opt/conda/bin/conda init bash

RUN /opt/conda/bin/conda create -n tsm -y python=3.8

# Make RUN commands use the new environment:
SHELL ["/opt/conda/bin/conda", "run", "--no-capture-output", "-n", "tsm", "/bin/bash", "-c"]

RUN conda install -y pytorch==1.10.1 torchvision==0.11.2 torchaudio==0.10.1 cudatoolkit=11.3 -c pytorch -c conda-forge && \
	conda clean -ya

# Install OpenCV
RUN conda install mamba -n base -c conda-forge -y && \
	mamba install -y opencv -c conda-forge && \
	conda clean -ya

RUN apt-get update && apt-get install llvm-8 -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN git clone -b v0.6 https://github.com/apache/incubator-tvm.git && \
	cd incubator-tvm && \
	git submodule update --init && \
	mkdir build && \
	cp cmake/config.cmake build/ && \
	cd build

RUN cd incubator-tvm/build && \
	sed -i 's/USE_CUDA OFF/USE_CUDA ON/' config.cmake && \
	sed -i 's/USE_LLVM OFF/USE_LLVM ON/' config.cmake && \
	cmake .. && \
	make -j$(nproc) && \
	cd ../python && \
	pip install . && \
	cd ../topi/python && \
	pip install .

# install onnx
RUN apt-get update && apt-get install protobuf-compiler libprotoc-dev -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
RUN pip3 install onnx onnxsim mpmath flatbuffers sympy packaging humanfriendly coloredlogs onnxruntime


RUN git clone https://github.com/mit-han-lab/temporal-shift-module

RUN wget https://hanlab.mit.edu/projects/tsm/models/mobilenetv2_jester_online.pth.tar -P /temporal-shift-module/online_demo/

WORKDIR /temporal-shift-module/online_demo
ENTRYPOINT ["/opt/conda/bin/conda", "run", "--no-capture-output", "-n", "tsm", "python", "main.py"]

# RUN git clone https://github.com/opencv/opencv /opencv && \
# 	cd /opencv && \
# 	git checkout 4.6.0
#
# RUN	git clone https://github.com/opencv/opencv_contrib /opencv_contrib && \
# 	cd /opencv_contrib && \
# 	git checkout 4.6.0

# RUN	mkdir /opencv/build && \
# 	cd /opencv/build && \
# 	cmake -D CMAKE_BUILD_TYPE=RELEASE \
# 		-D BUILD_opencv_python3=ON \
# 		-D BUILD_opencv_python2=OFF \
# 		-D PYTHON_DEFAULT_EXECUTABLE=/opt/conda/envs/tsm/bin/python \
#         -D BUILD_opencv_java=OFF \
# 		-D WITH_TBB=ON \
# 		-D WITH_V4L=ON \
# 		-D ENABLE_FAST_MATH=ON \
# 		-D WITH_OPENCL=OFF \
# 		-D WITH_OPENGL=ON \
# 		-D WITH_CUDA=ON \
# 		-D CUDA_FAST_MATH=ON \
# 		-D WITH_CUBLAS=ON \
# 		-D CUDA_ARCH_BIN=6.1 \
# 		-D CUDA_TOOLKIT_ROOT_DIR:PATH=/usr/local/cuda \
# 		-D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
# 		.. && \
# 	export NUMPROC=$(nproc --all) && \
# 	make -j$NUMPROC && \
# 	make install
