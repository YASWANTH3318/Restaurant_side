import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloggerPostsPage extends StatefulWidget {
  const BloggerPostsPage({super.key});

  @override
  State<BloggerPostsPage> createState() => _BloggerPostsPageState();
}

class _BloggerPostsPageState extends State<BloggerPostsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _dummyPosts = [];

  @override
  void initState() {
    super.initState();
    // Add dummy data for demonstration
    _dummyPosts = [
      {
        'title': 'Getting Started with Food Blogging',
        'content': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'status': 'published',
        'views': 245,
        'likes': 32,
        'image': 'https://via.placeholder.com/150',
      },
      {
        'title': 'Top 10 Street Foods You Must Try',
        'content': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'draft',
        'views': 0,
        'likes': 0,
        'image': 'https://via.placeholder.com/150',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create new post screen
              },
              child: const Icon(Icons.add),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Posts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: 'All',
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Posts'),
                          ),
                          DropdownMenuItem(
                            value: 'Published',
                            child: Text('Published'),
                          ),
                          DropdownMenuItem(
                            value: 'Draft',
                            child: Text('Drafts'),
                          ),
                        ],
                        onChanged: (value) {
                          // TODO: Implement filtering
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                _dummyPosts.isEmpty
                    ? _buildEmptyState()
                    : Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _dummyPosts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final post = _dummyPosts[index];
                            return _buildPostCard(post);
                          },
                        ),
                      ),
              ],
            ),
          );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first blog post to get started',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create post page
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post image
          if (post['image'] != null)
            Image.network(
              post['image'],
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chip
                Align(
                  alignment: Alignment.topRight,
                  child: Chip(
                    label: Text(
                      post['status'] == 'published' ? 'Published' : 'Draft',
                      style: TextStyle(
                        color: post['status'] == 'published'
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: post['status'] == 'published'
                        ? Colors.green[100]
                        : Colors.orange[100],
                  ),
                ),
                
                // Title
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Date
                Text(
                  'Posted on ${_formatDate(post['date'])}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Content preview
                Text(
                  post['content'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats
                Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${post['views']} views',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes']} likes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        // TODO: Navigate to edit post
                      },
                    ),
                    TextButton.icon(
                      icon: Icon(
                        post['status'] == 'published'
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        post['status'] == 'published'
                            ? 'Unpublish'
                            : 'Publish',
                      ),
                      onPressed: () {
                        // TODO: Toggle publish state
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 