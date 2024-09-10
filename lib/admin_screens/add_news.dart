import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadLatestNewsPage extends StatefulWidget {
  @override
  _UploadLatestNewsPageState createState() => _UploadLatestNewsPageState();
}

class _UploadLatestNewsPageState extends State<UploadLatestNewsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _editingNewsId; // For tracking the news being edited

  void _uploadOrEditNews() async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      if (_editingNewsId == null) {
        // If not editing, add new news
        await _firestore.collection('latest_news').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If editing, update the news
        await _firestore.collection('latest_news').doc(_editingNewsId).update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _editingNewsId = null; // Reset editing state
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('News saved successfully!')),
      );

      _titleController.clear();
      _descriptionController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields.')),
      );
    }
  }

  void _deleteNews(String id) async {
    await _firestore.collection('latest_news').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('News deleted successfully!')),
    );
  }

  void _startEditingNews(String id, String title, String description) {
    setState(() {
      _editingNewsId = id;
      _titleController.text = title;
      _descriptionController.text = description;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Latest News'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'News Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'News Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadOrEditNews,
              child:
                  Text(_editingNewsId == null ? 'Upload News' : 'Update News'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700], // Button color
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('latest_news')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final newsList = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final news = newsList[index];
                      final id = news.id;
                      final title = news['title'];
                      final description = news['description'];

                      return ListTile(
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () =>
                                  _startEditingNews(id, title, description),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteNews(id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
