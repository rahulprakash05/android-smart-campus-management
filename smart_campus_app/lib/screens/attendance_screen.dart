// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _attendedController = TextEditingController();

  _AttendanceResult? _result;

  @override
  void dispose() {
    _totalController.dispose();
    _attendedController.dispose();
    super.dispose();
  }

  String? _validateTotal(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the total number of classes';
    final total = int.tryParse(text);
    if (total == null) return 'Enter a valid whole number';
    if (total <= 0) return 'Total classes must be greater than 0';
    return null;
  }

  String? _validateAttended(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the number of classes attended';
    final attended = int.tryParse(text);
    if (attended == null) return 'Enter a valid whole number';
    final total = int.tryParse(_totalController.text.trim());
    if (total != null && attended > total) {
      return 'Attended classes cannot be more than total classes';
    }
    return null;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _result = null);
      return;
    }
    final total = int.parse(_totalController.text.trim());
    final attended = int.parse(_attendedController.text.trim());
    setState(() {
      _result = _AttendanceResult(total: total, attended: attended);
    });
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    _totalController.clear();
    _attendedController.clear();
    _formKey.currentState?.reset();
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analyzer'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your class counts to check your attendance.',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Total classes',
                    hintText: 'e.g. 100',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateTotal,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _attendedController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Classes attended',
                    hintText: 'e.g. 68',
                    prefixIcon: Icon(Icons.how_to_reg_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateAttended,
                  onFieldSubmitted: (_) => _calculate(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calculate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_result != null) _buildResult(context, _result!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, _AttendanceResult r) {
    final textTheme = Theme.of(context).textTheme;
    final ok = r.isSatisfactory;
    final color = ok ? Colors.green.shade700 : Colors.red.shade700;
    final label = ok ? 'Satisfactory' : 'Low Attendance Warning';

    String tip;
    if (ok) {
      tip = r.classesCanMiss > 0
          ? 'You can miss up to ${r.classesCanMiss} more class(es) and stay at 75% or above.'
          : 'You are exactly at the limit. Avoid missing any more classes.';
    } else {
      tip = 'To reach 75%, you would need to attend the next ${r.classesNeeded} '
          'classes without missing any.';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              '${r.percentageText}%',
              style: textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (r.percentage / 100).clamp(0.0, 1.0),
                minHeight: 10,
                color: color,
                backgroundColor: color.withAlpha(40),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${r.attended} of ${r.total} classes attended',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tip,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Attendance % = attended ÷ total × 100',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceResult {
  final int total;
  final int attended;

  const _AttendanceResult({required this.total, required this.attended});

  double get percentage => attended / total * 100;

  // Integer comparison avoids decimal rounding problems at exactly 75%.
  bool get isSatisfactory => attended * 100 >= total * 75;

  // Smallest number of extra classes (all attended) that brings you to 75%.
  int get classesNeeded => 3 * total - 4 * attended;

  // Largest number of extra classes you can miss and still be at 75% or above.
  int get classesCanMiss => (4 * attended - 3 * total) ~/ 3;

  String get percentageText {
    final text = percentage.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}