# Day 3 範例檔

| 檔案 | 對應投影片 |
|---|---|
| k8s/cuda-smi.yaml | 1.3 不透過 Run:ai 跑 GPU Pod |
| train/Dockerfile、train/train.py | 3.4、3.6、3.7、4.5（單 GPU / 2 GPU 訓練、checkpoint 接續） |
| ops/runai-demo.sh | 2.5～5.3 全部 CLI 指令，依序貼上 |
| ops/daily-check.sh | 6.5 日常巡檢 |

## 課前準備
- Harbor：`fg01/train:v1`（用 train/Dockerfile build）、`library/vllm-openai`、`nvidia/cuda:12.6.3-base-ubuntu24.04`
- Run:ai：Department `tiss`、Project `it` / `ss` / `sm` / `st` 與配額；node pool `h200`、`pro6000`
- Run:ai 資產：環境 `jupyter-lab`、`vllm`；運算資源 `one-gpu`、`half-gpu`；資料來源 `datasets`（/data）、`models`（/models）；Harbor 憑證
- `models` PVC 放好 `Qwen2.5-1.5B-Instruct`
- Inference 需要 Knative：`kubectl get pods -n knative-serving`

節點名稱（h200-01、pro6000-01）、網址（runai.tiss.internal）與配額數字請依實際環境替換。
