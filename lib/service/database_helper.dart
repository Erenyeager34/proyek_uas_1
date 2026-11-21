import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('jamuku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // =========================================
  // PEMBUATAN DATABASE
  // =========================================

  Future<void> _createDB(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // 1. Tabel Produk
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga INTEGER NOT NULL,
        stok INTEGER NOT NULL
      )
    ''');

    // 2. Tabel Bahan Baku
    await db.execute('''
      CREATE TABLE bahan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        stok REAL NOT NULL,
        satuan TEXT NOT NULL,
        batas_min REAL NOT NULL
      )
    ''');

    // 3. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        jenis TEXT NOT NULL,
        total INTEGER NOT NULL,
        keterangan TEXT
      )
    ''');

    // 4. Tabel Detail Penjualan
    await db.execute('''
      CREATE TABLE detail_penjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_transaksi INTEGER NOT NULL,
        id_produk INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,

        FOREIGN KEY (id_transaksi)
          REFERENCES transaksi (id)
          ON DELETE CASCADE,

        FOREIGN KEY (id_produk)
          REFERENCES produk (id)
      )
    ''');

    await _seedInitialData(db);
  }

  // =========================================
  // DATA AWAL / SEEDING
  // =========================================

  Future<void> _seedInitialData(Database db) async {
    // Produk awal
    await db.insert('produk', {
      'nama': 'STMJ Original',
      'kategori': 'STMJ',
      'harga': 12000,
      'stok': 20,
    });

    await db.insert('produk', {
      'nama': 'STMJ Jahe Merah',
      'kategori': 'STMJ',
      'harga': 14000,
      'stok': 15,
    });

    await db.insert('produk', {
      'nama': 'Tolak Angin Sachet',
      'kategori': 'Jamu Sachet',
      'harga': 5000,
      'stok': 30,
    });

    await db.insert('produk', {
      'nama': 'Kuku Bima Ener-G',
      'kategori': 'Jamu Sachet',
      'harga': 3000,
      'stok': 25,
    });

    // Bahan baku awal
    await db.insert('bahan', {
      'nama': 'Madu Murni',
      'stok': 2.5,
      'satuan': 'Liter',
      'batas_min': 1.0,
    });

    await db.insert('bahan', {
      'nama': 'Telur Bebek/Ayam',
      'stok': 24,
      'satuan': 'Butir',
      'batas_min': 10,
    });

    await db.insert('bahan', {
      'nama': 'Susu Kental Manis',
      'stok': 6,
      'satuan': 'Kaleng',
      'batas_min': 3,
    });

    await db.insert('bahan', {
      'nama': 'Jahe Merah Segar',
      'stok': 0.5,
      'satuan': 'Kg',
      'batas_min': 1.0,
    });
  }

  // =========================================
  // OPERASI PRODUK
  // =========================================

  Future<List<Map<String, dynamic>>> getAllProduk() async {
    final db = await instance.database;

    return await db.query('produk', orderBy: 'nama ASC');
  }

  // =========================================
  // OPERASI BAHAN BAKU
  // =========================================

  Future<List<Map<String, dynamic>>> getAllBahan() async {
    final db = await instance.database;

    return await db.query('bahan', orderBy: 'nama ASC');
  }

  Future<List<Map<String, dynamic>>> getBahanMenipis() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT * FROM bahan
      WHERE stok <= batas_min
      ORDER BY nama ASC
    ''');
  }

  // =========================================
  // CATAT PENJUALAN
  // OTOMATIS MENGURANGI STOK PRODUK
  // =========================================

  Future<int> simpanPenjualan({
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await instance.database;

    if (items.isEmpty) {
      throw Exception('Daftar penjualan masih kosong.');
    }

    if (totalHarga <= 0) {
      throw Exception('Total harga harus lebih dari 0.');
    }

    // Validasi data item dan total subtotal
    int totalSubtotal = 0;

    // Mengumpulkan jumlah produk agar produk yang sama
    // tidak lolos validasi stok secara terpisah.
    final Map<int, int> totalQtyProduk = {};

    for (final item in items) {
      final idProduk = item['id_produk'];
      final qty = item['qty'];
      final subtotal = item['subtotal'];

      if (idProduk is! int || idProduk <= 0) {
        throw Exception('ID produk tidak valid.');
      }

      if (qty is! int || qty <= 0) {
        throw Exception('Jumlah produk harus lebih dari 0.');
      }

      if (subtotal is! int || subtotal <= 0) {
        throw Exception('Subtotal produk tidak valid.');
      }

      totalSubtotal += subtotal;

      totalQtyProduk[idProduk] = (totalQtyProduk[idProduk] ?? 0) + qty;
    }

    if (totalSubtotal != totalHarga) {
      throw Exception('Total penjualan tidak sesuai dengan subtotal produk.');
    }

    final tanggalSekarang = DateTime.now().toIso8601String();

    // Semua proses penjualan berada dalam satu transaksi database.
    // Jika salah satu proses gagal, perubahan akan dibatalkan.
    return await db.transaction((txn) async {
      // 1. Validasi stok setiap produk
      for (final entry in totalQtyProduk.entries) {
        final produk = await txn.query(
          'produk',
          where: 'id = ?',
          whereArgs: [entry.key],
          limit: 1,
        );

        if (produk.isEmpty) {
          throw Exception('Produk dengan ID ${entry.key} tidak ditemukan.');
        }

        final stokSaatIni = produk.first['stok'] as int;
        final qtyDibutuhkan = entry.value;

        if (stokSaatIni < qtyDibutuhkan) {
          throw Exception(
            'Stok ${produk.first['nama']} tidak mencukupi. '
            'Stok tersedia: $stokSaatIni',
          );
        }
      }

      // 2. Simpan transaksi utama
      final idTransaksi = await txn.insert('transaksi', {
        'tanggal': tanggalSekarang,
        'jenis': 'MASUK',
        'total': totalHarga,
        'keterangan': 'Penjualan Jamu/STMJ',
      });

      // 3. Simpan detail penjualan dan kurangi stok
      for (final item in items) {
        await txn.insert('detail_penjualan', {
          'id_transaksi': idTransaksi,
          'id_produk': item['id_produk'],
          'qty': item['qty'],
          'subtotal': item['subtotal'],
        });

        await txn.rawUpdate(
          '''
          UPDATE produk
          SET stok = stok - ?
          WHERE id = ? AND stok >= ?
          ''',
          [item['qty'], item['id_produk'], item['qty']],
        );
      }

      return idTransaksi;
    });
  }

  // =========================================
  // CATAT PENGELUARAN
  // =========================================

  Future<int> simpanPengeluaran(int nominal, String keterangan) async {
    final db = await instance.database;

    if (nominal <= 0) {
      throw Exception('Nominal pengeluaran harus lebih dari 0.');
    }

    if (keterangan.trim().isEmpty) {
      throw Exception('Keterangan pengeluaran wajib diisi.');
    }

    return await db.insert('transaksi', {
      'tanggal': DateTime.now().toIso8601String(),
      'jenis': 'KELUAR',
      'total': nominal,
      'keterangan': keterangan.trim(),
    });
  }

  // =========================================
  // RINGKASAN KEUANGAN HARI INI
  // =========================================

  Future<Map<String, int>> getRingkasanHariIni() async {
    final db = await instance.database;

    final todayPrefix = DateTime.now().toIso8601String().substring(0, 10);

    final masukRes = await db.rawQuery(
      '''
      SELECT SUM(total) AS total
      FROM transaksi
      WHERE jenis = 'MASUK'
      AND tanggal LIKE ?
      ''',
      ['$todayPrefix%'],
    );

    final keluarRes = await db.rawQuery(
      '''
      SELECT SUM(total) AS total
      FROM transaksi
      WHERE jenis = 'KELUAR'
      AND tanggal LIKE ?
      ''',
      ['$todayPrefix%'],
    );

    // SUM() dapat menghasilkan NULL jika belum ada transaksi.
    final masuk = (masukRes.first['total'] as num?)?.toInt() ?? 0;
    final keluar = (keluarRes.first['total'] as num?)?.toInt() ?? 0;

    return {'pemasukan': masuk, 'pengeluaran': keluar, 'saldo': masuk - keluar};
  }
}
