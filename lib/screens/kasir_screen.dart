import 'package:flutter/material.dart';
import 'package:proyek_uas_1/service/database_helper.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  // Menyimpan daftar produk dari database
  List<Map<String, dynamic>> _daftarProduk = [];

  // Menyimpan jumlah beli berdasarkan ID produk
  // Contoh: {1: 2, 2: 3}
  final Map<int, int> _keranjang = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  // =========================================
  // MEMUAT PRODUK DARI DATABASE
  // =========================================

  Future<void> _muatProduk() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.getAllProduk();

      if (!mounted) return;

      setState(() {
        _daftarProduk = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    }
  }

  // =========================================
  // FORMAT RUPIAH
  // =========================================

  String _formatRupiah(int nominal) {
    final str = nominal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  // =========================================
  // MENGHITUNG TOTAL ITEM
  // =========================================

  int get _totalItem {
    int total = 0;

    _keranjang.forEach((id, qty) {
      total += qty;
    });

    return total;
  }

  // =========================================
  // MENGHITUNG TOTAL HARGA
  // =========================================

  int get _totalHarga {
    int total = 0;

    for (var produk in _daftarProduk) {
      final int id = produk['id'] as int;
      final int qty = _keranjang[id] ?? 0;

      if (qty > 0) {
        total += (produk['harga'] as int) * qty;
      }
    }

    return total;
  }

  // =========================================
  // MENAMBAHKAN PRODUK KE KERANJANG
  // =========================================

  void _tambahQty(Map<String, dynamic> produk) {
    final int id = produk['id'] as int;
    final int stokTersedia = produk['stok'] as int;
    final int qtySekarang = _keranjang[id] ?? 0;

    if (_isSaving) return;

    if (qtySekarang < stokTersedia) {
      setState(() {
        _keranjang[id] = qtySekarang + 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${produk['nama']} tidak mencukupi '
            '(Sisa: $stokTersedia)',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // =========================================
  // MENGURANGI JUMLAH PRODUK
  // =========================================

  void _kurangQty(int id) {
    if (_isSaving) return;

    final int qtySekarang = _keranjang[id] ?? 0;

    if (qtySekarang > 1) {
      setState(() {
        _keranjang[id] = qtySekarang - 1;
      });
    } else {
      setState(() {
        _keranjang.remove(id);
      });
    }
  }

  // =========================================
  // MENYIMPAN TRANSAKSI PENJUALAN
  // =========================================

  Future<void> _prosesSimpanTransaksi() async {
    if (_keranjang.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, dynamic>> itemsUntukDb = [];

      for (var produk in _daftarProduk) {
        final int id = produk['id'] as int;
        final int qty = _keranjang[id] ?? 0;

        if (qty > 0) {
          final int harga = produk['harga'] as int;

          itemsUntukDb.add({
            'id_produk': id,
            'qty': qty,
            'subtotal': harga * qty,
          });
        }
      }

      // Simpan transaksi melalui DatabaseHelper
      await DatabaseHelper.instance.simpanPenjualan(
        totalHarga: _totalHarga,
        items: itemsUntukDb,
      );

      if (!mounted) return;

      setState(() {
        _keranjang.clear();
      });

      await _muatProduk();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Penjualan berhasil dicatat dan stok otomatis berkurang!',
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================
  // TAMPILAN UTAMA
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text(
          'Catat Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _muatProduk,
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Produk',
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : Column(
              children: [
                // =================================
                // DAFTAR PRODUK JAMU & STMJ
                // =================================
                Expanded(
                  child: _daftarProduk.isEmpty
                      ? const Center(child: Text('Belum ada produk tersedia.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _daftarProduk.length,
                          itemBuilder: (context, index) {
                            final produk = _daftarProduk[index];

                            final int id = produk['id'] as int;
                            final int stok = produk['stok'] as int;
                            final int qty = _keranjang[id] ?? 0;

                            final bool habis = stok <= 0;
                            final bool kategoriSTMJ =
                                produk['kategori'] == 'STMJ';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: qty > 0
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade200,
                                  width: qty > 0 ? 1.5 : 1,
                                ),
                              ),

                              color: habis
                                  ? Colors.grey.shade100
                                  : Colors.white,

                              elevation: 0,

                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),

                                child: Row(
                                  children: [
                                    // ICON PRODUK
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: kategoriSTMJ
                                          ? Colors.amber.shade100
                                          : Colors.green.shade100,

                                      child: Icon(
                                        kategoriSTMJ
                                            ? Icons.local_cafe
                                            : Icons.spa,
                                        color: kategoriSTMJ
                                            ? Colors.orange.shade800
                                            : const Color(0xFF1B5E20),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // INFORMASI PRODUK
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            produk['nama'].toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: habis
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                          ),

                                          const SizedBox(height: 2),

                                          Text(
                                            _formatRupiah(
                                              produk['harga'] as int,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          Text(
                                            habis
                                                ? 'Stok Habis'
                                                : 'Tersedia: $stok',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: habis
                                                  ? Colors.red
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // TOMBOL KURANG DAN TAMBAH
                                    if (!habis)
                                      Row(
                                        children: [
                                          if (qty > 0) ...[
                                            IconButton(
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => _kurangQty(id),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red,
                                              ),
                                            ),

                                            Text(
                                              '$qty',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],

                                          IconButton(
                                            onPressed: _isSaving
                                                ? null
                                                : () => _tambahQty(produk),
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Color(0xFF2E7D32),
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // =================================
                // PANEL CHECKOUT
                // =================================
                if (_totalItem > 0)
                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        // TOTAL PEMBELIAN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalItem Item Dipilih',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),

                              Text(
                                _formatRupiah(_totalHarga),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TOMBOL SIMPAN TRANSAKSI
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onPressed: _isSaving ? null : _prosesSimpanTransaksi,

                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),

                          label: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
