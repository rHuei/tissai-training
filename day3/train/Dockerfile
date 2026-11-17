# 3.4 / 3.6 訓練範例 image
#   docker build -t harbor.tiss.internal/fg01/train:v1 .
#   docker push harbor.tiss.internal/fg01/train:v1
FROM nvcr.io/nvidia/pytorch:25.01-py3
COPY train.py /workspace/train.py
WORKDIR /workspace
