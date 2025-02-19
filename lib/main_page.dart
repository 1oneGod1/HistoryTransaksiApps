import 'dart:convert';
import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DateTime _selectedDate = DateTime.now();
  List<String> _categories = ["Makanan", "Transportasi", "Hiburan", "Lainnya"];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _categories =
          prefs.getStringList('categories') ??
          ["Makanan", "Transportasi", "Hiburan", "Lainnya"];

      String? transactionsString = prefs.getString('transactions');
      if (transactionsString != null) {
        List<dynamic> decodedList = jsonDecode(transactionsString);
        _transactions =
            decodedList.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', _categories);
    await prefs.setString('transactions', jsonEncode(_transactions));
  }

  void _addOrEditTransaction({Map<String, dynamic>? transaction}) {
    TextEditingController amountController = TextEditingController();
    TextEditingController noteController = TextEditingController();
    String selectedCategory = _categories[0];

    if (transaction != null) {
      amountController.text = transaction["amount"].toString();
      noteController.text = transaction["note"];
      selectedCategory = transaction["category"];
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              transaction == null ? "Tambah Pengeluaran" : "Edit Pengeluaran",
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Jumlah Pengeluaran"),
                ),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  items:
                      _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                ),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: "Catatan (Opsional)"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Batal"),
              ),
              if (transaction != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _transactions.remove(transaction);
                    });
                    _saveData();
                    Navigator.pop(context);
                  },
                  child: Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty) return;

                  setState(() {
                    if (transaction == null) {
                      _transactions.add({
                        "date":
                            _selectedDate
                                .toIso8601String(), // 🔹 Gunakan tanggal yang dipilih!
                        "amount": double.parse(amountController.text),
                        "category": selectedCategory,
                        "note": noteController.text,
                      });
                    } else {
                      transaction["amount"] = double.parse(
                        amountController.text,
                      );
                      transaction["category"] = selectedCategory;
                      transaction["note"] = noteController.text;
                    }
                  });

                  _saveData();
                  Navigator.pop(context);
                },
                child: Text("Simpan"),
              ),
            ],
          ),
    );
  }

  void _manageCategories() {
    TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Kelola Kategori"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._categories.map((category) {
                  return ListTile(
                    title: Text(category),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _categories.remove(category);
                        });
                        _saveData();
                        Navigator.pop(context);
                        _manageCategories();
                      },
                    ),
                  );
                }).toList(),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: "Tambah Kategori"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (categoryController.text.isNotEmpty) {
                    setState(() {
                      _categories.add(categoryController.text);
                    });
                    _saveData();
                  }
                  Navigator.pop(context);
                },
                child: Text("Tambah"),
              ),
            ],
          ),
    );
  }

  void _showMonthlySummary() {
    double total = _transactions
        .where((t) => DateTime.parse(t["date"]).month == _selectedDate.month)
        .fold(0, (sum, t) => sum + t["amount"]);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Ringkasan Bulanan"),
            content: Text("Total Pengeluaran: Rp. ${total.toStringAsFixed(2)}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tutup"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> dailyTransactions =
        _transactions
            .where((t) => DateTime.parse(t["date"]).day == _selectedDate.day)
            .toList();

    double totalDailyExpense = dailyTransactions.fold(
      0,
      (sum, t) => sum + t["amount"],
    );

    return Scaffold(
      appBar: CalendarAppBar(
        backButton: false,
        accent: Color.fromARGB(255, 10, 60, 170),
        onDateChanged: (value) {
          setState(() {
            _selectedDate = value;
          });
        },
        firstDate: DateTime.now().subtract(Duration(days: 140)),
        lastDate: DateTime.now(),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Total Pengeluaran di tanggal Ini",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp. ${totalDailyExpense.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 54, 86, 244),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dailyTransactions.length,
              itemBuilder: (context, index) {
                final transaction = dailyTransactions[index];
                return Card(
                  child: ListTile(
                    title: Text(transaction["category"]),
                    subtitle: Text(
                      "${transaction["note"]} \n${DateTime.parse(transaction["date"]).toLocal()}"
                          .split('.')[0],
                    ),
                    trailing: Text(
                      "Rp. ${transaction["amount"].toStringAsFixed(2)}",
                    ),
                    onTap:
                        () => _addOrEditTransaction(transaction: transaction),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTransaction(),
        backgroundColor: Color.fromARGB(255, 245, 159, 0),
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: _showMonthlySummary, icon: Icon(Icons.book)),
            IconButton(onPressed: _manageCategories, icon: Icon(Icons.list)),
          ],
        ),
      ),
    );
  }
}
