# add 7z tar and zip archivers
FROM nvidia/cuda:9.0-cudnn7-devel

# https://docs.docker.com/engine/examples/running_ssh_service/
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:Ubuntu@41' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN mkdir ~/.ssh/
RUN touch ~/.ssh/authorized_keys

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

# writing env variables to /etc/profile as mentioned here https://docs.docker.com/engine/examples/running_ssh_service/#run-a-test_sshd-container
RUN echo "export CONDA_DIR=/opt/conda" >> /etc/profile
RUN echo "export PATH=$CONDA_DIR/bin:$PATH" >> /etc/profile

RUN mkdir -p $CONDA_DIR && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh && \
    apt-get update && \
    apt-get install -y wget git libhdf5-dev g++ graphviz openmpi-bin nano && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo "c59b3dd3cad550ac7596e0d599b91e75d88826db132e4146030ef471bb434e9a *Miniconda3-4.2.12-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash /Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    ln /usr/lib/x86_64-linux-gnu/libcudnn.so /usr/local/cuda/lib64/libcudnn.so && \
    ln /usr/lib/x86_64-linux-gnu/libcudnn.so.7 /usr/local/cuda/lib64/libcudnn.so.7 && \
    ln /usr/include/cudnn.h /usr/local/cuda/include/cudnn.h  && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh

ENV NB_USER keras
ENV NB_UID 1000

RUN echo "export NB_USER=keras" >> /etc/profile
RUN echo "export NB_UID=1000" >> /etc/profile

RUN echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH" >> /etc/profile
RUN echo "export CPATH=/usr/include:/usr/include/x86_64-linux-gnu:/usr/local/cuda/include:$CPATH" >> /etc/profile
RUN echo "export LIBRARY_PATH=/usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LIBRARY_PATH" >> /etc/profile
RUN echo "export CUDA_HOME=/usr/local/cuda" >> /etc/profile
RUN echo "export CPLUS_INCLUDE_PATH=$CPATH" >> /etc/profile
RUN echo "export KERAS_BACKEND=tensorflow" >> /etc/profile

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown keras $CONDA_DIR -R  

USER keras

RUN  mkdir -p /home/keras/notebook

# Python
ARG python_version=3.6

RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install tensorflow-gpu && \
    conda install Pillow scikit-learn notebook pandas matplotlib mkl nose pyyaml six h5py && \
    conda install theano pygpu bcolz && \
    pip install keras kaggle-cli lxml opencv-python requests scipy tqdm visdom && \
    conda install pytorch=0.4.0 cuda90 -c pytorch && \
    conda install torchvision -c pytorch && \
    pip install imgaug && \
    conda clean -yt

ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV CPATH /usr/include:/usr/include/x86_64-linux-gnu:/usr/local/cuda/include:$CPATH
ENV LIBRARY_PATH /usr/local/cuda/lib64:/lib/x86_64-linux-gnu:$LIBRARY_PATH
ENV CUDA_HOME /usr/local/cuda
ENV CPLUS_INCLUDE_PATH $CPATH
ENV KERAS_BACKEND tensorflow

USER keras

WORKDIR /home/keras/notebook

EXPOSE 8888 6006 22

CMD jupyter notebook --port=8888 --ip=0.0.0.0 --no-browser