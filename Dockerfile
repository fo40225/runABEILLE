FROM continuumio/miniconda3:23.10.0-1

RUN apt update
RUN apt install -y libopenblas0-openmp

RUN conda install -y -c defaults nomkl numpy==1.23.5 scipy scikit-learn numexpr tensorflow==2.12.0 pandas r-base

COPY . /app
WORKDIR /app
RUN Rscript requirements.R
RUN Rscript requirements.R
