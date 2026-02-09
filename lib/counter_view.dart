import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  late TextEditingController _stepController;

  @override
  void initState() {
    super.initState();
    _stepController = TextEditingController(text: '${_controller.step}');
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _updateStep(String value) {
    int? newStep = int.tryParse(value);
    if (newStep != null && newStep > 0) {
      setState(() {
        _controller.setStep(newStep);
        _stepController.text = '$newStep';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: SRP Version")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 40),
            // Section untuk mengatur Step
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      // Slider untuk Step
                      Expanded(
                        child: Slider(
                          value: _controller.step.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${_controller.step}',
                          onChanged: (value) {
                            _updateStep('${value.toInt()}');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Langkah saat ini: ${_controller.step}'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Tombol Decrement dan Increment
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _controller.decrement()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  child: const Text(
                    '- Kurang',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _controller.reset()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _controller.increment()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  child: const Text(
                    '+ Tambah',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
