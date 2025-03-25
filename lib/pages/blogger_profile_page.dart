import 'package:flutter/material.dart';
import '../models/blogger.dart';
import '../models/blog_post.dart';
import '../models/reel.dart';
import '../models/review.dart';
import '../services/blog_service.dart';
import '../services/review_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:video_player/video_player.dart';
import '../utils/date_format_util.dart';

class BloggerProfilePage extends StatefulWidget {
  final String bloggerId;
  final String? bloggerName; // Optional parameter for navigation

  const BloggerProfilePage({
    super.key, 
    required this.bloggerId,
    this.bloggerName,
  });

  @override
  State<BloggerProfilePage> createState() => _BloggerProfilePageState();
}

class _BloggerProfilePageState extends State<BloggerProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Blogger? _blogger;
  List<BlogPost> _posts = [];
  List<Reel> _reels = [];
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBloggerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBloggerData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Get blogger data
      final blogger = await BlogService.getBlogger(widget.bloggerId);
      if (blogger == null) {
        throw Exception('Blogger not found');
      }
      
      // Check if current user is following this blogger
      if (currentUser != null) {
        _isFollowing = blogger.followers.contains(currentUser.uid);
      }
      
      // Get posts and reels
      final posts = await BlogService.getBloggerPosts(widget.bloggerId);
      final reels = await BlogService.getBloggerReels(widget.bloggerId);

      if (mounted) {
        setState(() {
          _blogger = blogger;
          _posts = posts;
          _reels = reels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to sign in to follow bloggers')),
      );
      return;
    }

    if (_blogger == null) return;

    setState(() {
      // Optimistically update UI
      if (_isFollowing) {
        _blogger!.followers.remove(currentUser.uid);
      } else {
        _blogger!.followers.add(currentUser.uid);
      }
      _isFollowing = !_isFollowing;
    });

    try {
      if (_isFollowing) {
        await BlogService.followBlogger(widget.bloggerId, currentUser.uid);
      } else {
        await BlogService.unfollowBlogger(widget.bloggerId, currentUser.uid);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          if (_isFollowing) {
            _blogger!.followers.remove(currentUser.uid);
          } else {
            _blogger!.followers.add(currentUser.uid);
          }
          _isFollowing = !_isFollowing;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_blogger?.name ?? widget.bloggerName ?? 'Blogger Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Reels'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBloggerData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildProfileHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsList(),
                          _buildReelsList(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProfileHeader() {
    if (_blogger == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _blogger!.profileImageUrl != null
                    ? NetworkImage(_blogger!.profileImageUrl!)
                    : null,
                child: _blogger!.profileImageUrl == null
                    ? Text(
                        _blogger!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 30),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _blogger!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('@${_blogger!.username}'),
                    const SizedBox(height: 8),
                    if (_blogger!.bio != null) Text(_blogger!.bio!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Posts', _posts.length.toString()),
              _buildStat('Reels', _reels.length.toString()),
              _buildStat('Followers', DateFormatUtil.formatNumberIndian(_blogger!.followers.length)),
            ],
          ),
          const SizedBox(height: 16),
          if (_blogger!.specialties.isNotEmpty) ...[
            const Text(
              'Specialties',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blogger!.specialties.map((specialty) {
                return Chip(
                  label: Text(specialty),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing
                    ? Colors.grey[300]
                    : Theme.of(context).primaryColor,
                foregroundColor: _isFollowing
                    ? Colors.black
                    : Colors.white,
              ),
              child: Text(_isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return const Center(
        child: Text('No posts yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.imageUrl != null)
                Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    if (post.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: post.tags.map((tag) {
                          return Chip(
                            label: Text('#$tag'),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 12),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatUtil.formatDateIndian(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.favorite, 
                              color: post.likes.contains(FirebaseAuth.instance.currentUser?.uid)
                                  ? Colors.red
                                  : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatUtil.formatNumberIndian(post.likes.length),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReelsList() {
    if (_reels.isEmpty) {
      return const Center(
        child: Text('No reels yet'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              reel.thumbnailUrl != null
                  ? Image.network(
                      reel.thumbnailUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.videocam,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatUtil.formatNumberIndian(reel.likes.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white.withOpacity(0.8),
                  size: 36,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 