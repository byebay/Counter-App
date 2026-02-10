class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;

  List<String> get history {
    if (_history.isEmpty) return [];
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
