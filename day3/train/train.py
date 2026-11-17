"""Day 3 訓練範例：單 GPU 或 torchrun 多 GPU，每個 epoch 存 checkpoint，被搶佔後接著跑。

單 GPU：  python train.py --epochs 20
2 GPU：   torchrun --nproc_per_node=2 train.py --epochs 20
環境變數 CKPT_DIR：checkpoint 存放目錄（請放在 NFS PVC 上，例如 /data/ckpt/<人>/<工作>）
資料用隨機產生的合成資料，不需要下載資料集。
"""
import argparse
import os
import time

import torch
import torch.distributed as dist
import torch.nn as nn
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data import DataLoader, TensorDataset
from torch.utils.data.distributed import DistributedSampler

p = argparse.ArgumentParser()
p.add_argument('--epochs', type=int, default=20)
p.add_argument('--batch', type=int, default=512)
p.add_argument('--samples', type=int, default=200_000)
args = p.parse_args()

distributed = 'RANK' in os.environ
if distributed:
    dist.init_process_group('nccl')
    rank, world = dist.get_rank(), dist.get_world_size()
    local = int(os.environ.get('LOCAL_RANK', 0))
else:
    rank, world, local = 0, 1, 0
torch.cuda.set_device(local)
dev = torch.device('cuda', local)
if rank == 0:
    print(f'[rank0] world_size={world} gpu={torch.cuda.get_device_name(local)}', flush=True)

# 合成資料：固定亂數種子，每個 rank 產生相同資料，再由 sampler 切分
g = torch.Generator().manual_seed(0)
x = torch.randn(args.samples, 1024, generator=g)
y = torch.randint(0, 10, (args.samples,), generator=g)
ds = TensorDataset(x, y)
sampler = DistributedSampler(ds) if distributed else None
dl = DataLoader(ds, batch_size=args.batch, sampler=sampler, shuffle=sampler is None, num_workers=2, pin_memory=True)

model = nn.Sequential(nn.Linear(1024, 4096), nn.ReLU(), nn.Linear(4096, 4096), nn.ReLU(), nn.Linear(4096, 10)).to(dev)
opt = torch.optim.AdamW(model.parameters(), lr=1e-3)
if distributed:
    model = DDP(model, device_ids=[local])
raw = model.module if distributed else model

ckpt_dir = os.environ.get('CKPT_DIR', '/tmp/ckpt')
ckpt = os.path.join(ckpt_dir, 'last.pt')
start = 0
if os.path.exists(ckpt):
    s = torch.load(ckpt, map_location=dev)
    raw.load_state_dict(s['model'])
    opt.load_state_dict(s['opt'])
    start = s['epoch'] + 1
    if rank == 0:
        print(f'resume from epoch {start}', flush=True)

loss_fn = nn.CrossEntropyLoss()
for epoch in range(start, args.epochs):
    if sampler:
        sampler.set_epoch(epoch)
    t0 = time.time()
    model.train()
    total = 0.0
    for xb, yb in dl:
        xb, yb = xb.to(dev, non_blocking=True), yb.to(dev, non_blocking=True)
        opt.zero_grad()
        loss = loss_fn(model(xb), yb)
        loss.backward()
        opt.step()
        total += loss.item()
    if rank == 0:
        print(f'epoch {epoch + 1}/{args.epochs}  loss {total / len(dl):.3f}  gpus={world}  {time.time() - t0:.1f}s', flush=True)
        os.makedirs(ckpt_dir, exist_ok=True)
        torch.save({'model': raw.state_dict(), 'opt': opt.state_dict(), 'epoch': epoch}, ckpt + '.tmp')
        os.replace(ckpt + '.tmp', ckpt)  # 先寫暫存檔再改名，避免存到一半被中斷
        print(f'saved checkpoint {ckpt}', flush=True)
    if distributed:
        dist.barrier()

if distributed:
    dist.destroy_process_group()
