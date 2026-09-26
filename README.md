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
| `docker-compose.yml` | Service `filebrowser`, volume folder model + database, health check |
| `config.yaml` | Format **v1.5.x (stable)**: satu source `/srv`, login password (min. 12 karakter), tanpa signup |
| `.env.example` | Variabel untuk menjalankan lokal |

> Dokumentasi online dan branch `main` upstream memakai format konfigurasi **v2 (beta)**, misalnya blok
> `http:`. Format itu **tidak dikenali** image `stable` dan membuat container gagal start. Saat meng-upgrade ke
> v2, sesuaikan `config.yaml`.

## Deploy di Coolify

1. **Siapkan folder di VPS** (Coolify → Servers → localhost → Terminal, atau SSH):
   ```sh
   sudo mkdir -p /data/stack-inspection/models /data/filebrowser-quantum
   sudo chown -R 1000:1000 /data/stack-inspection/models /data/filebrowser-quantum
   ```
   FileBrowser berjalan sebagai user `1000`; tanpa langkah ini muncul `permission denied`.
2. **New Resource → Docker Compose** → pilih repo ini (branch default) → Save.
3. **Environment Variables**: isi `FILEBROWSER_ADMIN_PASSWORD` (min. 12 karakter). Simpan juga di password manager.
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

Diuji lokal (Colima) dengan `gtstef/filebrowser:stable` v1.5.x: container *healthy*, config diterima, login
admin dari env berhasil (200), password salah ditolak (401), folder `carton-v1` terlihat di `/srv`.
