import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageFeedbackScreen extends StatefulWidget {
  @override
  _ManageFeedbackScreenState createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete feedback: $e')),
      );
    }
  }

  void _editFeedback(String feedbackId, String currentFeedback) {
    TextEditingController _editController =
        TextEditingController(text: currentFeedback);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Feedback'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: 'Feedback',
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('feedback')
                      .doc(feedbackId)
                      .update({
                    'feedback': _editController.text,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feedback updated successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update feedback: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getCustomerName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] : 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Feedback'),
        backgroundColor: Colors.yellow[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('feedback').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final feedbackDocs = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              var feedbackData =
                  feedbackDocs[index].data() as Map<String, dynamic>;
              var feedbackId = feedbackDocs[index].id;
              var feedbackText = feedbackData['feedback'] ?? '';
              var rating = feedbackData['rating'] ?? 0;
              var userId = feedbackData['user_id'] ?? '';

              return FutureBuilder<String>(
                future: _getCustomerName(userId),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                      subtitle: Text('Rating: $rating'),
                    );
                  }

                  return Card(
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      title: Text('${nameSnapshot.data} - Rating: $rating'),
                      subtitle: Text(feedbackText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.yellow[700]),
                            onPressed: () =>
                                _editFeedback(feedbackId, feedbackText),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFeedback(feedbackId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
