class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 1; // Variabel untuk menentukan langkah increment/decrement

  int get value => _counter; // Getter untuk akses data
  int get step => _step; // Getter untuk langkah

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  }

  void increment() => _counter += _step;
  void decrement() { if (_counter >= _step) _counter -= _step; }
  void reset() => _counter = 0;
}
