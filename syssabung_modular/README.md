# SysHub - Grow A Chicken Fighter (Modular Edition)

Struktur script modular profesional untuk game **Grow a Chicken Fighter** di Roblox, berbasis pustaka antarmuka **WindUI**.

---

## 📁 Struktur File & Direktori

```text
syssabung_modular/
├── loader.lua              # Loader 1-baris untuk di-paste di Executor Roblox
├── init.lua                # File orkestrator utama (WindUI Window, Tabs & Background Threads)
├── core/
│   └── context.lua         # Shared Context (Services, Remotes, Utility, State & Scanner)
└── modules/
    ├── player.lua          # Tab Player: Visual ESP & Streamer Mode
    ├── farm.lua            # Tab Farm: Fast Rebirth, Tower, Sweep, UFO, Arena
    ├── coop.lua            # Tab Coop: Coop & Recycler, Feeder, Nest Eggs, Incubator
    ├── flock.lua           # Tab Flock: Auto Open Egg, Sell, Promote, Fuse, Charms
    ├── event.lua           # Tab Event: Jurassic Pass & Quests, Ancient Egg, Auto Chicken Boss
    ├── rewards.lua         # Tab Rewards: Play Today, Daily Streak, Codes, Milestones
    └── misc.lua            # Tab Misc: Server Management, FPS Optimizer, Config Manager & Webhook
```

---

## 🚀 Cara Menjalankan di Roblox Executor

### Metode A: Online via GitHub (Rekomendasi)
1. Buat repository publik baru di akun GitHub Anda (misalnya: `syssabung`).
2. Upload seluruh isi folder `syssabung_modular` ke repository tersebut.
3. Buka file `loader.lua`, ganti bagian:
   ```lua
   local GITHUB_BASE = "https://raw.githubusercontent.com/USERNAME_ANDA/syssabung/main/syssabung_modular/"
   ```
4. Di executor Roblox Anda, jalankan 1 baris berikut:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME_ANDA/syssabung/main/syssabung_modular/loader.lua"))()
   ```

### Metode B: Offline / Lokal di Executor
1. Buka folder `workspace` pada executor Anda.
2. Salin folder `syssabung_modular` ke dalam folder `workspace` tersebut.
3. Di executor, jalankan:
   ```lua
   loadstring(readfile("syssabung_modular/loader.lua"))()
   ```
