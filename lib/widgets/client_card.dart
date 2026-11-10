import 'package:flutter/material.dart';
import '../models/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(client.name),
        subtitle: Text(
          client.hasLocation
              ? 'Location available (${client.locationText})'
              : 'Location not captured',
        ),
        leading: const CircleAvatar(child: Icon(Icons.person)),
        trailing: Icon(
          client.hasLocation ? Icons.location_on : Icons.location_off,
          color: client.hasLocation ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

