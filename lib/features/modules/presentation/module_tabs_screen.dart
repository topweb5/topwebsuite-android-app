import 'package:flutter/material.dart';

import '../../shared/domain/resource_config.dart';
import '../../shared/presentation/resource_workspace_screen.dart';

class ModuleTabsScreen extends StatelessWidget {
  const ModuleTabsScreen({
    super.key,
    required this.title,
    required this.configs,
  });

  final String title;
  final List<ResourceConfig> configs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: configs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final config in configs) Tab(text: config.title)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final config in configs)
              ResourceWorkspaceScreen(config: config),
          ],
        ),
      ),
    );
  }
}
