// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import 'academic_screen.dart';
import 'attendance_screen.dart';
import 'career_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openModule(BuildContext context, String title) {
        if (title == 'Career Guidance') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CareerScreen()),
      );
      return;
    }
        if (title == 'Academic Assistant') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AcademicScreen()),
      );
      return;
    }
    if (title == 'AI Campus Chatbot') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }
    if (title == 'Attendance Analyzer') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title screen will be built next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const modules = <_Module>[
      _Module(
        title: 'AI Campus Chatbot',
        subtitle: 'Ask general questions about studies and campus life',
        icon: Icons.chat_bubble_outline,
        color: Color(0xFF1565C0),
      ),
      _Module(
        title: 'Academic Assistant',
        subtitle: 'Notes, summaries, quizzes and practice questions',
        icon: Icons.menu_book_outlined,
        color: Color(0xFF2E7D32),
      ),
      _Module(
        title: 'Attendance Analyzer',
        subtitle: 'Check your attendance percentage and status',
        icon: Icons.fact_check_outlined,
        color: Color(0xFFEF6C00),
      ),
      _Module(
        title: 'Career Guidance',
        subtitle: 'Career options, missing skills and a learning roadmap',
        icon: Icons.work_outline,
        color: Color(0xFF6A1B9A),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Campus'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome, Student',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a tool to get started.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final module in modules)
              _ModuleCard(
                module: module,
                onTap: () => _openModule(context, module.title),
              ),
            const SizedBox(height: 8),
            Text(
              'AI answers are for general guidance only and may contain mistakes.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _Module({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: module.color.withAlpha(31),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: module.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(module.subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}