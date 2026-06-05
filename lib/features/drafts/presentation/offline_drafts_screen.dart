import 'package:flutter/material.dart';

class OfflineDraftsScreen extends StatelessWidget {
  const OfflineDraftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Drafts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Draft autosave is active',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'New records in the shared module editors are saved locally as you type. A successful backend save clears the local draft for that module.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
