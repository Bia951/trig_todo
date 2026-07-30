import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/todo_provider.dart';
import 'screens/app_shell.dart';
import 'theme/trig_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrigBootstrap());
}

class TrigBootstrap extends StatefulWidget {
  const TrigBootstrap({super.key});

  @override
  State<TrigBootstrap> createState() => _TrigBootstrapState();
}

class _TrigBootstrapState extends State<TrigBootstrap> {
  TodoProvider? _todoProvider;
  Object? _bootstrapError;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final provider = await TodoProvider.bootstrap();
      if (!mounted) {
        provider.dispose();
        return;
      }
      setState(() => _todoProvider = provider);

      // Notification setup can prompt for permission on a first launch.  Run it
      // only after the app itself is visible, and never make the UI wait for it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(provider.initializeReminderScheduler());
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to start Trig: $error\n$stackTrace');
      if (mounted) {
        setState(() => _bootstrapError = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _todoProvider;
    if (provider != null) {
      return TrigApp(todoProvider: provider);
    }

    if (_bootstrapError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupError(
          onRetry: () {
            setState(() => _bootstrapError = null);
            unawaited(_bootstrap());
          },
        ),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _StartupLoading(),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to start Trig.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class TrigApp extends StatelessWidget {
  const TrigApp({
    required this.todoProvider,
    super.key,
    this.lightDynamic,
    this.darkDynamic,
  });

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
  final TodoProvider todoProvider;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return _TrigMaterialApp(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          todoProvider: todoProvider,
        );
      },
    );
  }
}

class _TrigMaterialApp extends StatelessWidget {
  const _TrigMaterialApp({
    required this.todoProvider,
    this.lightDynamic,
    this.darkDynamic,
  });

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
  final TodoProvider todoProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TodoProvider>.value(
      value: todoProvider,
      child: MaterialApp(
        title: 'Trig',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: TrigTheme.light(lightDynamic),
        darkTheme: TrigTheme.dark(darkDynamic),
        home: const AppShell(),
      ),
    );
  }
}
