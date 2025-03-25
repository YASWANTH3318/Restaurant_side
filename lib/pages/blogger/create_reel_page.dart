import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class CreateReelPage extends StatefulWidget {
  const CreateReelPage({super.key});

  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}

class _CreateReelPageState extends State<CreateReelPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  
  bool _isLoading = false;
  File? _videoFile;
  List<String> _tags = [];
  String _newTag = '';
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      
      if (pickedFile != null) {
        setState(() {
          _videoFile = File(pickedFile.path);
          _isVideoInitialized = false;
        });
        
        // Initialize video controller
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_videoFile!);
        
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  void _addTag() {
    if (_newTag.isNotEmpty && !_tags.contains(_newTag)) {
      setState(() {
        _tags.add(_newTag);
        _newTag = '';
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveReel() async {
    if (_formKey.currentState!.validate()) {
      if (_videoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a video for your reel')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to create a reel')),
          );
          return;
        }

        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};

        // Prepare reel data
        final reel = {
          'userId': user.uid,
          'userName': userData['name'] ?? user.displayName ?? 'Anonymous',
          'userImage': userData['profileImageUrl'] ?? user.photoURL ?? '',
          'description': _descriptionController.text.trim(),
          'tags': _tags,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': [],
          'views': 0,
          'comments': [],
          'metadata': {
            'createdBy': 'app',
            'duration': _videoController?.value.duration.inSeconds ?? 0,
          },
        };

        // TODO: Upload video to Firebase Storage and add URL to reel data
        // TODO: Generate thumbnail from video and upload to Firebase Storage

        // Save reel to Firestore
        await FirebaseFirestore.instance.collection('reels').add(reel);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel uploaded successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving reel: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveReel,
            icon: const Icon(Icons.upload),
            label: const Text('Upload'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video preview
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _videoFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.video_library_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select Video',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Maximum 60 seconds',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : _isVideoInitialized
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: _videoController!.value.aspectRatio,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _videoController!.value.isPlaying
                                                ? Icons.pause_circle_outline
                                                : Icons.play_circle_outline,
                                            size: 64,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (_videoController!.value.isPlaying) {
                                                _videoController!.pause();
                                              } else {
                                                _videoController!.play();
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Write a caption for your reel',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 500,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Add a tag',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _newTag = value;
                              });
                            },
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTag,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 