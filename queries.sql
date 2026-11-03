-- =====================================================================
-- Analisis Penjualan E-Commerce (data dummy, Jan - Jun 2026)
-- Dialek: MySQL / MariaDB. Tabel: data_bersih (283 baris)
-- Revenue = total order berstatus 'Selesai'
-- Semua hasil sudah dicocokkan dengan PivotTable di Excel.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Struktur tabel (impor data_bersih.csv setelah tabel dibuat)
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS penjualan;
USE penjualan;

CREATE TABLE IF NOT EXISTS data_bersih (
  order_id VARCHAR(20),
  tanggal DATE,
  pelanggan VARCHAR(50),
  kota VARCHAR(30),
  kategori VARCHAR(30),
  produk VARCHAR(50),
  qty INT,
  harga_satuan INT,
  diskon DECIMAL(4,2),
  metode_bayar VARCHAR(30),
  status VARCHAR(20),
  total DECIMAL(12,2)
);

-- Cek impor: harus 283 baris
SELECT COUNT(*) AS jumlah_baris FROM data_bersih;


-- ---------------------------------------------------------------------
-- 1. KPI utama
-- Hasil: 283 order, 247 selesai, revenue 76.692.500, AOV sekitar 310.496
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS total_order,
       SUM(status = 'Selesai') AS order_selesai,
       SUM(CASE WHEN status = 'Selesai' THEN total END) AS revenue,
       SUM(CASE WHEN status = 'Selesai' THEN total END) * 1.0 / SUM(status = 'Selesai') AS aov
FROM data_bersih;


-- ---------------------------------------------------------------------
-- 2. Revenue, jumlah order, dan AOV per bulan
-- Hasil: revenue Maret tertinggi (17.551.250), Juni terendah (5.946.000)
-- ---------------------------------------------------------------------
SELECT DATE_FORMAT(tanggal, '%Y-%m') AS bulan,
       COUNT(*) AS order_selesai,
       SUM(total) AS revenue,
       ROUND(AVG(total), 0) AS aov
FROM data_bersih
WHERE status = 'Selesai'
GROUP BY bulan
ORDER BY bulan;


-- ---------------------------------------------------------------------
-- 3. Pertumbuhan revenue bulan ke bulan (MoM) dengan CTE dan LAG
-- Hasil: Maret +56,8%, Juni -61,6%
-- ---------------------------------------------------------------------
WITH bulanan AS (
  SELECT DATE_FORMAT(tanggal, '%Y-%m') AS bulan,
         SUM(total) AS revenue
  FROM data_bersih
  WHERE status = 'Selesai'
  GROUP BY bulan
)
SELECT bulan,
       revenue,
       ROUND((revenue * 1.0 / LAG(revenue) OVER (ORDER BY bulan) - 1) * 100, 1) AS mom_pct
FROM bulanan;


-- ---------------------------------------------------------------------
-- 4. Kontribusi revenue per kategori (window function)
-- Hasil: Elektronik 39,0%, Fashion 30,9%, Rumah Tangga 14,2%,
--        Kecantikan 10,6%, Olahraga 5,3%
-- ---------------------------------------------------------------------
SELECT kategori,
       SUM(total) AS revenue,
       ROUND(SUM(total) * 100.0 / SUM(SUM(total)) OVER (), 1) AS kontribusi_pct
FROM data_bersih
WHERE status = 'Selesai'
GROUP BY kategori
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- 5. Top 5 produk berdasarkan revenue
-- Hasil: Smartwatch memimpin (Rp 13,585 juta, sekitar 18% dari revenue)
-- ---------------------------------------------------------------------
SELECT produk, kategori, SUM(qty) AS unit_terjual, SUM(total) AS revenue
FROM data_bersih
WHERE status = 'Selesai'
GROUP BY produk, kategori
ORDER BY revenue DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- 6. Cancel rate per metode pembayaran
-- Hasil: COD 16,7% (11 dari 66), E-Wallet 2,1% (2 dari 94)
-- ---------------------------------------------------------------------
SELECT metode_bayar,
       COUNT(*) AS total_order,
       SUM(status = 'Dibatalkan') AS dibatalkan,
       ROUND(SUM(status = 'Dibatalkan') * 100.0 / COUNT(*), 1) AS cancel_rate_pct
FROM data_bersih
GROUP BY metode_bayar
ORDER BY cancel_rate_pct DESC;


-- ---------------------------------------------------------------------
-- 7. Pelanggan dengan lebih dari satu order selesai (HAVING)
-- Catatan: pada data dummy ini ke-30 pelanggan semuanya repeat order,
-- jadi hasilnya tidak mencerminkan loyalitas pelanggan di data nyata.
-- ---------------------------------------------------------------------
SELECT pelanggan, COUNT(*) AS jumlah_order, SUM(total) AS total_belanja
FROM data_bersih
WHERE status = 'Selesai'
GROUP BY pelanggan
HAVING COUNT(*) > 1
ORDER BY total_belanja DESC
LIMIT 10;
