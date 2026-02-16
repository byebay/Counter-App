import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  final String username;

  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  CounterController({required this.username});

  int get value => _counter;
  int get step => _step;

  /// Return last 5 entries (or fewer)
  List<String> get history {
    if (_history.isEmpty) return [];
    return _history.length <= 5 ? List.of(_history) : _history.sublist(_history.length - 5);
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('counter_$username', _counter);
      await prefs.setInt('step_$username', _step);
      await prefs.setStringList('history_$username', _history);
    } catch (_) {
      // ignore storage errors in controller; UI can still work
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _counter = prefs.getInt('counter_$username') ?? 0;
      _step = prefs.getInt('step_$username') ?? 1;
      final saved = prefs.getStringList('history_$username');
      if (saved != null) {
        _history.clear();
        _history.addAll(saved);
      }
    } catch (_) {
      // ignore
    }
  }

  void _addHistory(String activity) {
    final time = _getCurrentTime();
    _history.add('User $username $activity pada jam $time');
    // persist asynchronously
    _saveToStorage();
  }

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
      _saveToStorage();
    }
  }

  void increment() {
    _counter += _step;
    _addHistory('menambah +$_step');
    _saveToStorage();
  }

  void decrement() {
    if (_counter >= _step) {
      _counter -= _step;
      _addHistory('mengurangi -$_step');
      _saveToStorage();
    }
  }

  void reset() {
    _counter = 0;
    _addHistory('mereset nilai counter');
    _saveToStorage();
  }
}
