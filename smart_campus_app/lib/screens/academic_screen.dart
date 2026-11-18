// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  static const Map<String, String> _modes = {
    'notes': 'Notes',
    'summary': 'Summary',
    'quiz': 'Quiz (5 MCQs)',
    'practice': 'Practice questions',
  };

  final _topicController = TextEditingController();
  final _resultKey = GlobalKey();

  String _mode = 'notes';
  bool _loading = false;
  String? _topicError;
  String? _error;
  String? _answer;

  // Remember the last request so Retry and the result title stay correct.
  String? _lastTopic;
  String? _lastMode;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.0,
        );
      }
    });
  }

  Future<void> _generate({bool retry = false}) async {
    if (_loading) return;

    final String topic;
    final String mode;

    if (retry && _lastTopic != null && _lastMode != null) {
      topic = _lastTopic!;
      mode = _lastMode!;
    } else {
      topic = _topicController.text.trim();
      mode = _mode;
      if (topic.isEmpty) {
        setState(() => _topicError = 'Please enter a subject or topic.');
        return;
      }
      if (topic.length < 2) {
        setState(() => _topicError = 'Topic is too short.');
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
      _topicError = null;
      _lastTopic = topic;
      _lastMode = mode;
    });

    try {
      final answer = await ApiService.academic(topic, mode);
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _loading = false;
      });
      _scrollToResult();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _copyAnswer() async {
    final text = _answer;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Assistant'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter a subject or topic and choose what you want to generate.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                enabled: !_loading,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Subject or topic',
                  hintText: 'e.g. Machine Learning',
                  prefixIcon: const Icon(Icons.school_outlined),
                  errorText: _topicError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_topicError != null) setState(() => _topicError = null);
                },
                onSubmitted: (_) => _generate(),
              ),
              const SizedBox(height: 8),
              Text('What do you want?', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _modes.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _mode == entry.key,
                      onSelected: _loading
                          ? null
                          : (_) => setState(() => _mode = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loading ? null : () => _generate(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate'),
              ),
              const SizedBox(height: 20),
              if (_loading) _buildLoading(),
              if (_error != null) _buildError(context),
              if (_answer != null) _buildResult(context),
              const SizedBox(height: 12),
              Text(
                'AI-generated content may contain mistakes. Please verify it '
                'with your textbooks and teachers.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 12),
          Text('Generating, please wait...'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error ?? 'Something went wrong.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _generate(retry: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final modeLabel = _modes[_lastMode] ?? 'Result';

    return Card(
      key: _resultKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$modeLabel: $_lastTopic',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  onPressed: _copyAnswer,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              _answer ?? '',
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}