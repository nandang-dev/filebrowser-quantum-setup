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
| `docker-compose.yaml` | Service `filebrowser`, volume folder model + database, health check |
| `.env.example` | Variabel untuk menjalankan lokal |

Konfigurasi memakai **config bawaan image** `stable`: satu source `/srv`, login password, pendaftaran akun
mati. Tidak ada file config di repo, karena bind mount file relatif (`./config.yaml`) di Coolify ter-mount
**kosong** sehingga FileBrowser gagal start (`Settings.Server.Sources ... required`).

> Jika nanti butuh kustomisasi, gunakan format config **v1.5.x** (lihat `backend/config.yaml` pada tag
> `v1.5.6-stable` upstream), bukan format v2 (beta) di dokumentasi online. Pasang lewat fitur file mount
> Coolify (Persistent Storage → File Mount) agar isinya benar-benar ikut.

## Deploy di Coolify

1. **Siapkan folder di VPS** (Coolify → Servers → localhost → Terminal, atau SSH):
   ```sh
   sudo mkdir -p /data/stack-inspection/models /data/filebrowser-quantum
   sudo chown -R 1000:1000 /data/stack-inspection/models /data/filebrowser-quantum
   ```
   FileBrowser berjalan sebagai user `1000`; tanpa langkah ini muncul `permission denied`.
2. **New Resource → Docker Compose** → pilih repo ini (branch default) → Save.
3. **Environment Variables**: isi `FILEBROWSER_ADMIN_PASSWORD` (disarankan min. 12 karakter). Simpan juga di password manager.
4. **Domain**: di pengaturan service `filebrowser`, isi `https://files.bagdja.com:80`
   (`:80` = port di dalam container, tidak muncul di browser). DNS `A files → IP VPS` harus sudah aktif.
5. **Deploy**. Status harus *Running (healthy)*. Buka `https://files.bagdja.com`, login `admin` + password langkah 3.

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

## Menjalankan lokal (opsional)

```sh
cp .env.example .env   # isi password
docker compose up -d   # tidak mem-publish port; akses lewat Coolify/proxy, atau tambahkan `ports: ["8081:80"]`
```

Di Mac (Colima/Docker Desktop), folder host harus berada di bawah `/Users/...` supaya bisa di-mount.

## Status pengujian

Diuji lokal (Colima) dengan `gtstef/filebrowser:stable` v1.5.x: container *healthy*, login admin dari env
berhasil (200), password salah ditolak (401), folder `carton-v1` terlihat di `/srv`. Di Coolify, mount
`./config.yaml` ternyata kosong → config file dihapus, memakai config bawaan image.
