import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './edit_garbage_collector.dart';

class ViewGarbageCollectorsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteGarbageCollector(BuildContext context, String collectorId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Garbage Collector'),
        content:
            Text('Are you sure you want to delete this garbage collector?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed) {
      try {
        await _firestore.collection('users').doc(collectorId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garbage collector deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete garbage collector: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Garbage Collectors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'garbage_collector')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No garbage collectors available.'));
          }

          final collectors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: collectors.length,
            itemBuilder: (context, index) {
              final collector = collectors[index];
              final collectorId = collector.id;
              final collectorData = collector.data() as Map<String, dynamic>;
              final collectorName = collectorData['name'] ?? 'Unknown';
              final collectorEmail = collectorData['email'] ?? 'Unknown';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(collectorName),
                  subtitle: Text(collectorEmail),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditGarbageCollectorPage(
                                  collectorId: collectorId,
                                  collectorData: collectorData),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteGarbageCollector(context, collectorId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
