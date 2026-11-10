import 'package:flutter/material.dart';

class QueueEmptyWidget extends StatelessWidget {
  const QueueEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'The waiting queue is empty',
            style: TextStyle(fontSize: 18),
          ),
          Text('New registrations will appear here.'),
        ],
      ),
    );
  }
}

