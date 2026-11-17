#!/usr/bin/env bash
# 用 K8S 原生 CSR 幫使用者簽發個人憑證並產生 kubeconfig（Day 2 4.3–4.4）
# 用法：./issue-user-cert.sh <使用者> <群組> [有效天數，預設 90]
set -euo pipefail
U=$1; G=$2; DAYS=${3:-90}
KCFG=${U}.kubeconfig

openssl genrsa -out ${U}.key 2048
openssl req -new -key ${U}.key -out ${U}.csr -subj "/CN=${U}/O=${G}"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${U}
spec:
  request: $(base64 -w0 ${U}.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: $((DAYS * 86400))
  usages: [client auth]
EOF
kubectl certificate approve ${U}
sleep 2
kubectl get csr ${U} -o jsonpath='{.status.certificate}' | base64 -d > ${U}.crt
openssl x509 -in ${U}.crt -noout -subject -enddate

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
kubectl config set-cluster k8s --kubeconfig=${KCFG} --server=${SERVER} --certificate-authority=ca.crt --embed-certs
kubectl config set-credentials ${U} --kubeconfig=${KCFG} --client-certificate=${U}.crt --client-key=${U}.key --embed-certs
kubectl config set-context ${U} --kubeconfig=${KCFG} --cluster=k8s --user=${U}
kubectl config use-context ${U} --kubeconfig=${KCFG}
chmod 600 ${KCFG}
kubectl --kubeconfig=${KCFG} auth whoami
echo "完成：${KCFG}（含私鑰，只交給本人）"
