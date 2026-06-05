import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class TopwebsuiteApp extends ConsumerWidget {
  const TopwebsuiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Topwebsuite',
      debugShowCheckedModeBanner: false,
      theme: TopwebsuiteTheme.light(),
      darkTheme: TopwebsuiteTheme.dark(),
      routerConfig: router,
    );
  }
}
