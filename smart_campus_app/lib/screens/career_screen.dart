// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();
  final _resultKey = GlobalKey();

  bool _loading = false;
  String? _skillsError;
  String? _interestsError;
  String? _error;
  String? _answer;

  // Remember the last request so Retry works even if the fields change.
  String? _lastSkills;
  String? _lastInterests;

  @override
  void dispose() {
    _skillsController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _fillDemo() {
    setState(() {
      _skillsController.text = 'Python, SQL, statistics';
      _interestsController.text = 'data and problem solving';
      _skillsError = null;
      _interestsError = null;
    });
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

    final String skills;
    final String interests;

    if (retry && _lastSkills != null && _lastInterests != null) {
      skills = _lastSkills!;
      interests = _lastInterests!;
    } else {
      skills = _skillsController.text.trim();
      interests = _interestsController.text.trim();

      String? skillsError;
      String? interestsError;
      if (skills.isEmpty) {
        skillsError = 'Please enter your skills.';
      } else if (skills.length < 2) {
        skillsError = 'Skills are too short.';
      }
      if (interests.isEmpty) {
        interestsError = 'Please enter your interests.';
      } else if (interests.length < 2) {
        interestsError = 'Interests are too short.';
      }
      if (skillsError != null || interestsError != null) {
        setState(() {
          _skillsError = skillsError;
          _interestsError = interestsError;
        });
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
      _skillsError = null;
      _interestsError = null;
      _lastSkills = skills;
      _lastInterests = interests;
    });

    try {
      final answer = await ApiService.career(skills, interests);
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
        title: const Text('Career Guidance'),
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
                'Tell us your skills and interests to get three career options '
                'with a short learning roadmap.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _skillsController,
                enabled: !_loading,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Your skills',
                  hintText: 'e.g. Python, SQL, statistics',
                  prefixIcon: const Icon(Icons.build_outlined),
                  errorText: _skillsError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_skillsError != null) setState(() => _skillsError = null);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _interestsController,
                enabled: !_loading,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Your interests',
                  hintText: 'e.g. data and problem solving',
                  prefixIcon: const Icon(Icons.favorite_border),
                  errorText: _interestsError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_interestsError != null) setState(() => _interestsError = null);
                },
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _loading ? null : _fillDemo,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Fill an example'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading ? null : () => _generate(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get career guidance'),
              ),
              const SizedBox(height: 20),
              if (_loading) _buildLoading(),
              if (_error != null) _buildError(context),
              if (_answer != null) _buildResult(context),
              const SizedBox(height: 12),
              Text(
                'This is general AI-generated guidance, not professional career '
                'counselling.',
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
          Text('Preparing your guidance...'),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'General AI-generated guidance',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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