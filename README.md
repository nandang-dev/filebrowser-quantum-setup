# FileBrowser Quantum — Pengelola Model Deteksi

Web file manager untuk meng-upload dan mengelola file model deteksi (`.onnx`) yang dibaca
**Stack Inspection API**. Repo ini **hanya berisi konfigurasi**; aplikasinya memakai image resmi
[`gtstef/filebrowser`](https://github.com/gtsteffaniak/filebrowser) (Apache-2.0).

```
                 /data/stack-inspection/models   (folder di VPS)
                   ▲ baca-tulis              ▲ hanya-baca
        ┌──────────┴─────────┐     ┌─────────┴──────────────┐
        │ FileBrowser Quantum │     │ Stack Inspection API   │
        │ /srv                │     │ /app/models            │
        └─────────────────────┘     └────────────────────────┘
```

## Isi repo

| File | Isi |
|---|---|
| `docker-compose.yaml` | Service `filebrowser`, config + volume folder model + database, health check |
| `config.yaml` | Konfigurasi v1.5.x; set `server.baseURL` ke `/files` |
| `.env.example` | Variabel untuk menjalankan lokal |

Image **dikunci ke `gtstef/filebrowser:1.5.8-stable`**. Jangan pakai tag `stable`: sejak 9 Okt 2026 tag itu
menunjuk ke v2, yang menolak env `FILEBROWSER_DATABASE` (`[FATAL] FILEBROWSER_DATABASE environment variable is
deprecated`) dan memakai format config berbeda.

Konfigurasi di [config.yaml](./config.yaml) mempertahankan setelan default image v1.5.x dan mengatur
`server.baseURL: /files` agar aset dan API bekerja di subpath tersebut. Compose me-mount file ini
ke `/home/filebrowser/data/config.yaml` (lokasi config default image) dan mengecek health di `/files/health`.
Jangan gunakan mount file yang dibuat manual di menu Persistent Storage Coolify: file mount tersebut
sebelumnya ter-mount kosong dan membuat FileBrowser gagal start (`Settings.Server.Sources ... required`).

> Gunakan format config **v1.5.x** ini dengan image `1.5.8-stable`; format konfigurasi v2 berbeda.

## Deploy di Coolify

1. **Siapkan folder di VPS** (Coolify → Servers → localhost → Terminal, atau SSH):
   ```sh
   sudo mkdir -p /data/stack-inspection/models /data/filebrowser-quantum
   sudo chown -R 1000:1000 /data/stack-inspection/models /data/filebrowser-quantum
   ```
   FileBrowser berjalan sebagai user `1000`; tanpa langkah ini muncul `permission denied`.
2. **New Resource → Docker Compose** → pilih repo ini (branch default) → Save.
3. **Environment Variables**: isi `FILEBROWSER_ADMIN_PASSWORD` (disarankan min. 12 karakter). Simpan juga di password manager.
4. **Domain**: di pengaturan service `filebrowser`, isi `https://vision.enerren.com/files:80`
   (`:80` = port internal container yang dituju proxy Coolify, tidak muncul di browser).
   Compose mendeklarasikan port ini dengan `expose: 80`; jangan gunakan `ports:` untuk mem-publish port host,
   karena port 80/443 host dipakai proxy Coolify. DNS `A vision → IP VPS` harus sudah aktif.
5. **Deploy**. Status harus *Running (healthy)*. Buka `https://vision.enerren.com/files`, login `admin` + password langkah 3.

### Lupa password admin

Password admin **direset ke nilai `FILEBROWSER_ADMIN_PASSWORD` setiap kali start**. Lihat atau ganti nilainya di
Coolify → Environment Variables, lalu **Restart**.

## Hubungkan ke Stack Inspection API

Di aplikasi Stack Inspection API (Coolify → Persistent Storage):

| Source (host) | Destination | Mode |
|---|---|---|
| `/data/stack-inspection/models` | `/app/models` | **Read-only** |

## Cara upload model baru

1. Export model di Carton Trainer, misalnya `carton-v2`.
2. Di FileBrowser: buat folder **`carton-v2`**, lalu upload `carton-v2.onnx` dan `model-card.json` dari
   `carton-trainer/registry/models/carton-v2/`.
3. **Restart** Stack Inspection API (folder model dipindai saat start).
4. Cek `GET /api/v1/models`: `carton-v2` harus muncul (juga di dropdown Swagger).
5. Jadikan default dengan env `Vision__DefaultModel=carton-v2` di Stack Inspection API, lalu restart.

Jangan hapus model lama sebelum model baru terbukti baik (rollback = kembalikan `Vision__DefaultModel`).

## Keamanan

- Password kuat + aktifkan **2FA** (Profile → Security).
- Batasi akses ke IP kantor/VPN jika memungkinkan (firewall VPS / pengaturan proxy Coolify).
- FileBrowser hanya melihat folder model (`/srv`), tidak ke folder lain di server.

### Upgrade ke v2 (belum dilakukan)

Butuh pekerjaan terpisah: hapus env `FILEBROWSER_DATABASE`, siapkan config format v2 lewat File Mount Coolify
dengan `server.database` mengarah ke volume `/home/filebrowser/db` dan `server.database.migrateFrom` agar
database v1.5 (akun, 2FA) ikut dimigrasi. Uji lokal dulu dengan salinan database.

## Menjalankan lokal (opsional)

```sh
cp .env.example .env   # isi password
docker compose up -d   # tidak mem-publish port; akses lewat Coolify/proxy, atau tambahkan `ports: ["8081:80"]`
```

Di Mac (Colima/Docker Desktop), folder host harus berada di bawah `/Users/...` supaya bisa di-mount.

## Status pengujian

Diuji lokal (Colima) dengan `gtstef/filebrowser:stable` (saat itu v1.5.x): container *healthy*, login admin dari env
berhasil (200), password salah ditolak (401), folder `carton-v1` terlihat di `/srv`. Di Coolify, mount
`./config.yaml` ternyata kosong → config file dihapus, memakai config bawaan image.
