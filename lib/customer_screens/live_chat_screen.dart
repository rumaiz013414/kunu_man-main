import 'package:flutter/material.dart';

class LiveChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Chat'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              'Chat with a support agent here.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Handle message action here
              },
              child: Icon(Icons.message),
              backgroundColor: Colors.yellow[700],
            ),
          ),
        ],
      ),
    );
  }
}
