import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic>? data;
  final String Function(dynamic) timeAgo;

  const LocationCard({
    super.key,
    required this.name,
    required this.data,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          if (data == null)
            Text('Nessuna posizione',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)))
          else ...[
            if (data!['city'] != null)
              Text('📍 ${data!['city']}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
            Text('${(data!['lat'] as num).toStringAsFixed(4)}, ${(data!['lon'] as num).toStringAsFixed(4)}',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
            Text(timeAgo(data!['timestamp']),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ],
      ),
    );
  }
}
