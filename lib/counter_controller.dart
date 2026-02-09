class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 1; // Variabel untuk menentukan langkah increment/decrement
  final List<String> _history = []; // List untuk menampung riwayat aktivitas

  int get value => _counter; // Getter untuk akses data
  int get step => _step; // Getter untuk langkah

  // Getter untuk mengakses 5 riwayat terakhir
  List<String> get history {
    if (_history.isEmpty) return [];
    // Ambil 5 item terakhir dari history (atau lebih sedikit jika ada kurang dari 5)
    return _history.length <= 5
        ? _history
        : _history.sublist(_history.length - 5);
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _addHistory(String activity) {
    final time = _getCurrentTime();
    _history.add('$activity ($time)');
  }

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  }

  void increment() {
    _counter += _step;
    _addHistory('User menambah nilai sebesar $_step');
  }

  void decrement() {
    if (_counter >= _step) {
      _counter -= _step;
      _addHistory('User mengurangi nilai sebesar $_step');
    }
  }

  void reset() {
    _counter = 0;
    _addHistory('User mereset nilai counter');
  }
}
