#!/usr/bin/env bash
# Day 3 Demo 指令（依序貼上執行，不要整支直接跑）
# 參數依 Run:ai CLI 版本可能不同，以 runai <類型> submit --help 為準
IMG=harbor.tiss.internal

# ---- 2.5 登入 ----
runai login user -u ${UNAME}
runai project list
runai project set it
runai node list

# ---- 3.3 Workspace（CLI） ----
runai workspace submit jupyter-cli -p it --environment jupyter-lab --compute one-gpu --data-source datasets
runai workspace list
runai workspace describe jupyter-cli
runai workspace delete jupyter-cli

# ---- 3.4 單 GPU 訓練 ----
runai training submit train-1gpu -p it -i ${IMG}/fg01/train:v1 -g 1 --node-pools h200 \
  --existing-pvc claimname=datasets,path=/data -e CKPT_DIR=/data/ckpt/${UNAME}/1gpu \
  --command -- python train.py --epochs 20
runai training logs train-1gpu --follow

# ---- 3.6 2 GPU 訓練（4.5 搶佔示範會用到，epochs 設大一點） ----
runai training submit train-2gpu -p it -i ${IMG}/fg01/train:v1 -g 2 --node-pools h200 --large-shm \
  --existing-pvc claimname=datasets,path=/data -e CKPT_DIR=/data/ckpt/${UNAME}/2gpu \
  --command -- torchrun --nproc_per_node=2 train.py --epochs 40
runai training logs train-2gpu --follow

# ---- 4.2 推論服務 ----
runai inference submit qwen-cli -p it -i ${IMG}/library/vllm-openai:latest \
  -g 1 --node-pools h200 --serving-port 8000 \
  --existing-pvc claimname=models,path=/models --min-replicas 1 --max-replicas 1 \
  -- --model /models/Qwen2.5-1.5B-Instruct --served-model-name qwen
# URL=<網頁 Connections 的網址>
# curl -s $URL/v1/chat/completions -H 'Content-Type: application/json' \
#   -d '{"model":"qwen","messages":[{"role":"user","content":"你好"}]}'
runai inference delete qwen-cli

# ---- 4.4 GPU 分數 ----
for n in a b c; do
  runai workspace submit frac-$n -p it -i ${IMG}/nvidia/cuda:12.6.3-base-ubuntu24.04 \
    --gpu-portion-request 0.5 --node-pools pro6000 --command -- sleep infinity
done
runai workspace list
runai workspace exec frac-a -- nvidia-smi --query-gpu=name,memory.total --format=csv
runai workspace delete frac-a frac-b frac-c

# ---- 4.5 搶佔（train-2gpu 執行中時） ----
runai workspace submit ss-jupyter -p ss --environment jupyter-lab --compute one-gpu
runai workload list -A
runai training describe train-2gpu -p it
runai workspace delete ss-jupyter -p ss
runai training logs train-2gpu -p it --follow

# ---- 5.3 DCGM ----
kubectl -n gpu-operator port-forward svc/nvidia-dcgm-exporter 9400:9400 &
curl -s localhost:9400/metrics | grep -E '^DCGM_FI_DEV_(GPU_UTIL|FB_USED|GPU_TEMP|POWER_USAGE)'
