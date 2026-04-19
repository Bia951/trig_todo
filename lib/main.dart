import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'theme/trig_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final todoProvider = await TodoProvider.bootstrap();
  runApp(TrigBootstrap(todoProvider: todoProvider));
}

class TrigBootstrap extends StatelessWidget {
  const TrigBootstrap({required this.todoProvider, super.key});

  final TodoProvider todoProvider;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return TrigApp(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          todoProvider: todoProvider,
        );
      },
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
    return ChangeNotifierProvider<TodoProvider>.value(
      value: todoProvider,
      child: MaterialApp(
        title: 'Trig',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: TrigTheme.light(lightDynamic),
        darkTheme: TrigTheme.dark(darkDynamic),
        home: const HomeScreen(),
      ),
    );
  }
}
