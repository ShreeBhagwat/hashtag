import 'dart:developer';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promtTextField = TextEditingController();
  XFile? image;
  String responseText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 87, 72, 216),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 87, 72, 216),
        title: const Text(
          'Caption Generator',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (image != null)
            IconButton(
              onPressed: () {
                setState(() {
                  image = null;
                  responseText = '';
                  _promtTextField.clear();
                });
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              if (image == null)
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Upload a photo to generate captions',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              image == null
                  ? GestureDetector(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 86, 77, 187),
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onTap: () {
                        pickImageFromPhotos();
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 86, 77, 187),
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(image!.path),
                            height: 300,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: _promtTextField,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(color: Colors.white),
                    hintText: 'Enter a prompt',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 215, 214, 214)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                        foregroundColor: Color.fromARGB(255, 86, 77, 187),
                      ),
                      onPressed: () {
                        uploadToImageToFirestore();
                      },
                      child: const Text('Generate Captions')),
                ),
              ),
              if (responseText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 86, 77, 187),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.75,
                                child: Text(
                                  responseText.trim(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                  ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future pickImageFromPhotos() async {
    try {
      final ImagePicker picker = ImagePicker();
      await picker
          .pickImage(source: ImageSource.gallery, imageQuality: 30)
          .catchError((e) {
        log(e);
        return e;
      }).then((value) {
        setState(() {
          image = value;
        });
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future uploadToImageToFirestore() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final storageRef = FirebaseStorage.instance.ref();
    final file = File(image!.path);
    final ref = storageRef.child('images/${file.path.split('/').last}');
    final metaData = SettableMetadata(
      contentType: 'image/${file.path.split('.').last}',
    );
    await ref.putData(file.readAsBytesSync(), metaData).catchError((e) {
      setState(() {
        _isLoading = false;
      });
      log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error uploading image'),
        ),
      );

      return;
    }).then((value) {
      value.ref.getDownloadURL().then((value) {
        generateCaption(value);
      });
    });
  }

  Future generateCaption(String imageUrl) async {
    try {
      FirebaseFunctions.instance
          .httpsCallable(
        'generateCaptions',
      )
          .call({'text': 'Explain', 'photoUrl': imageUrl}).then((value) {
        responseText = value.data;
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      // show snackbar of error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }
}
