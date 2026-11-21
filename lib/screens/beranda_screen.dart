import 'package:flutter/material.dart';
import 'package:proyek_uas_1/service/database_helper.dart';

class BerandaScreen extends StatefulWidget {
  final Function(int) onPindahTab;

  const BerandaScreen({super.key, required this.onPindahTab});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Map<String, int> _ringkasan = {'pemasukan': 0, 'pengeluaran': 0, 'saldo': 0};

  List<Map<String, dynamic>> _bahanMenipis = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataDashboard();
  }

  Future<void> _muatDataDashboard() async {
    setState(() => _isLoading = true);
    final ringkasan = await DatabaseHelper.instance.getRingkasanHariIni();
    final menipis = await DatabaseHelper.instance.getBahanMenipis();

    setState(() {
      _ringkasan = ringkasan;
      _bahanMenipis = menipis;
      _isLoading = false;
    });
  }

  String _formatRupiah(int nominal) {
    final str = nominal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jamuku',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Jamu dicatat rapi, usaha makin terpantau',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: _muatDataDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : RefreshIndicator(
              onRefresh: _muatDataDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Kas Hari Ini',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatRupiah(_ringkasan['saldo'] ?? 0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: _buildItemKeuangan(
                                label: 'Penjualan',
                                nominal: _formatRupiah(
                                  _ringkasan['pemasukan'] ?? 0,
                                ),
                                icon: Icons.arrow_downward,
                                warnaIkon: Colors.lightGreenAccent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildItemKeuangan(
                                label: 'Pengeluaran',
                                nominal: _formatRupiah(
                                  _ringkasan['pengeluaran'] ?? 0,
                                ),
                                icon: Icons.arrow_upward,
                                warnaIkon: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTombolCepat(
                          judul: 'Catat Penjualan',
                          subjudul: 'Kasir Jamu & STMJ',
                          ikon: Icons.point_of_sale,
                          warna: const Color(0xFF2E7D32),
                          onTap: () => widget.onPindahTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTombolCepat(
                          judul: 'Catat Belanja',
                          subjudul: 'Pengeluaran Bahan',
                          ikon: Icons.shopping_bag_outlined,
                          warna: const Color(0xFFD84315),
                          onTap: () => _tampilkanDialogPengeluaran(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peringatan Stok Bahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onPindahTab(3),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_bahanMenipis.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Semua stok bahan baku masih aman.'),
                        ],
                      ),
                    )
                  else
                    ..._bahanMenipis.map(
                      (bahan) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        color: const Color(0xFFFFF8E1),
                        elevation: 0,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            bahan['nama'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sisa: ${bahan['stok']} ${bahan['satuan']} (Min: ${bahan['batas_min']} ${bahan['satuan']})',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.orange,
                          ),
                          onTap: () => widget.onPindahTab(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemKeuangan({
    required String label,
    required String nominal,
    required IconData icon,
    required Color warnaIkon,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white12,
          child: Icon(icon, size: 16, color: warnaIkon),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                nominal,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTombolCepat({
    required String judul,
    required String subjudul,
    required IconData ikon,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: warna.withValues(alpha: 0.12),
              child: Icon(ikon, color: warna),
            ),
            const SizedBox(height: 12),
            Text(
              judul,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subjudul,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanDialogPengeluaran() {
    final nominalCtrl = TextEditingController();
    final ketCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat Pengeluaran Usaha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nominalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                hintText: 'Contoh: 25000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan Belanja',
                hintText: 'Contoh: Beli Jahe Merah 1 Kg',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nominal = int.tryParse(nominalCtrl.text) ?? 0;
              if (nominal > 0) {
                await DatabaseHelper.instance.simpanPengeluaran(
                  nominal,
                  ketCtrl.text.isEmpty ? 'Belanja Bahan Jamu' : ketCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _muatDataDashboard();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
