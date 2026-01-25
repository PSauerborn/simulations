FROM debian:bookworm

WORKDIR /simulations

RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    python3 \
    python3-pip \
    python3-venv \
    git

RUN python3 -m venv venv

COPY requirements.txt .
RUN venv/bin/pip install -U pip && \
    venv/bin/pip install -r requirements.txt

COPY . .

ENTRYPOINT ["venv/bin/python", "./run_and_plot.py", "--fpm-binary-path", "venv/bin/fpm"]
