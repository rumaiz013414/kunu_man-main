import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GarbageProfilePhotoPage extends StatefulWidget {
  @override
  _GarbageProfilePhotoPageState createState() =>
      _GarbageProfilePhotoPageState();
}

class _GarbageProfilePhotoPageState extends State<GarbageProfilePhotoPage> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadImageToFirebase(BuildContext context) async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String fileName =
          'profile_pictures/${FirebaseAuth.instance.currentUser!.uid}.jpg';
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'profilePicture': downloadURL,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload complete')));
      Navigator.pop(context); // Redirect back to the profile page
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Photo'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null
                      ? Text('No image selected.')
                      : Image.file(_image!, height: 150, width: 150),
                  ElevatedButton(
                    onPressed: getImage,
                    child: Text('Select Image'),
                  ),
                  ElevatedButton(
                    onPressed: () => uploadImageToFirebase(context),
                    child: Text('Upload Image'),
                  ),
                ],
              ),
      ),
    );
  }
}
