#!/usr/bin/env bash
# 6.5 日常巡檢：只列出「不正常」的項目，沒有輸出代表正常
echo '== 節點 =='
kubectl get nodes --no-headers | grep -v ' Ready'
kubectl get nodes -L nvidia.com/gpu.count

echo '== GPU Operator =='
kubectl get pods -n gpu-operator --no-headers | grep -v -E 'Running|Completed'

echo '== Run:ai / Knative =='
for ns in runai runai-backend knative-serving; do
  kubectl get pods -n $ns --no-headers | grep -v -E 'Running|Completed'
done

echo '== Pending / Failed 工作 =='
runai workload list -A | grep -E 'Pending|Failed'

echo '== 資料 PVC =='
kubectl get pvc -A | grep -E 'datasets|models'
echo '（NAS 剩餘容量請到 NAS 管理介面確認；Run:ai 網頁 Clusters 狀態應為 Connected）'
