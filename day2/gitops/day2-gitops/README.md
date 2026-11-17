# day2-gitops

Day 2 M5（GitOps 基礎）、M6（GitOps 實務）示範用的 Git repo 範本。課前推到 Git 伺服器（main 分支）。

| 目錄 | 內容 | 對應簡報 |
|---|---|---|
| hello/base | Deployment、Service、PVC（任何環境都一樣） | 5.3 |
| hello/overlays/lab | namespace、image 版本、ConfigMap、HTTPRoute | 5.3–5.6、6.1、6.5 |
| platform | NetworkPolicy（M3）、RoleBinding（M4） | 6.2 |
| apps | hello、platform 兩個 Application（6.3 會再加 echo） | 6.2、6.3 |
| root.yaml | App of Apps 的入口 | 6.2 |

課前要改的地方：
- apps/*.yaml、root.yaml 的 repoURL
- 不是 fg01 時：overlay 的 namespace、image、httproute 的 hostnames，以及 platform、apps 裡的 namespace

本機檢查：`kubectl kustomize hello/overlays/lab`
