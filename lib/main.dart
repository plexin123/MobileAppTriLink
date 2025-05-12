import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safer approach to Firebase initialization
  try {
    if (Firebase.apps.isNotEmpty) {
      await Firebase.app().delete();
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkTree App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const LinkTreePage(),
      },
    );
  }
}

// ======================== Login Page ========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    Future.delayed(Duration.zero, () {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your password' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== Register Page ========================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== Link Model ========================
class Link {
  final String id;
  final String title;
  final String url;
  final String description;
  int clickCount;

  Link({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.clickCount = 0,
  });
}

// ======================== LinkTree Page ========================
class LinkTreePage extends StatefulWidget {
  const LinkTreePage({super.key});

  @override
  State<LinkTreePage> createState() => _LinkTreePageState();
}

class _LinkTreePageState extends State<LinkTreePage> {
  List<Link> links = [];
  bool isLoading = true;
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    Future.delayed(Duration.zero, ()
    {
      _loadLinks();
    });
  }

  Future<void> _loadLinks() async {
    setState(() => isLoading = true);
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('links')
          .where('userId', isEqualTo: userId)
          .orderBy('order', descending: false)
          .get();

      final loadedLinks = snapshot.docs.map((doc) {
        final data = doc.data();
        return Link(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          url: data['url'] ?? '',
          description: data['description'] ?? '',
          clickCount: data['clickCount'] ?? 0,
        );
      }).toList();

      setState(() {
        links = loadedLinks;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading links: $e');
      setState(() => isLoading = false);
    }
  }

  // Helper method to open URL
  Future<void> _launchUrl(String url, String linkId) async {
    // Update click count in Firestore
    try {
      await FirebaseFirestore.instance.collection('links').doc(linkId).update({
        'clickCount': FieldValue.increment(1),
      });

      // Update local state
      setState(() {
        final linkIndex = links.indexWhere((link) => link.id == linkId);
        if (linkIndex != -1) {
          links[linkIndex].clickCount++;
        }
      });

      // Format URL if needed
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }

      // Launch URL
      final Uri uri = Uri.parse(formattedUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    } catch (e) {
      print('Error updating click count: $e');
    }
  }

  void _showLinkDialog({Link? existingLink}) {
    final titleCtrl = TextEditingController(text: existingLink?.title ?? '');
    final urlCtrl = TextEditingController(text: existingLink?.url ?? '');
    final descCtrl = TextEditingController(text: existingLink?.description ?? '');
    bool isEditing = existingLink != null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Link' : 'Add New Link'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Title cannot be empty' : null,
              ),
              TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'URL cannot be empty' : null,
                keyboardType: TextInputType.url,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                Text('Click count: ${existingLink.clickCount}'),
              ],
            ],
          ),
        ),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteLink(existingLink.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final userId = currentUser?.uid;
              if (userId == null) return;

              Navigator.pop(context);

              if (isEditing) {
                await _updateLink(
                  existingLink.id,
                  titleCtrl.text,
                  urlCtrl.text,
                  descCtrl.text,
                );
              } else {
                await _addLink(
                  titleCtrl.text,
                  urlCtrl.text,
                  descCtrl.text,
                );
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLink(String title, String url, String description) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    try {
      setState(() => isLoading = true);

      final data = {
        'title': title,
        'url': url,
        'description': description,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'order': links.length, // Add at the end
        'clickCount': 0,
      };

      final docRef = await FirebaseFirestore.instance.collection('links').add(data);

      final newLink = Link(
        id: docRef.id,
        title: title,
        url: url,
        description: description,
        clickCount: 0,
      );

      setState(() {
        links.add(newLink);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add link')),
      );
    }
  }

  Future<void> _updateLink(String id, String title, String url, String description) async {
    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('links').doc(id).update({
        'title': title,
        'url': url,
        'description': description,
      });

      setState(() {
        final index = links.indexWhere((link) => link.id == id);
        if (index != -1) {
          final clickCount = links[index].clickCount;
          links[index] = Link(
            id: id,
            title: title,
            url: url,
            description: description,
            clickCount: clickCount,
          );
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update link')),
      );
    }
  }

  Future<void> _deleteLink(String id) async {
    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('links').doc(id).delete();

      // Update order for remaining items
      final batch = FirebaseFirestore.instance.batch();
      final remainingLinks = links.where((link) => link.id != id).toList();

      for (var i = 0; i < remainingLinks.length; i++) {
        final docRef = FirebaseFirestore.instance.collection('links').doc(remainingLinks[i].id);
        batch.update(docRef, {'order': i});
      }

      await batch.commit();

      setState(() {
        links.removeWhere((link) => link.id == id);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete link')),
      );
    }
  }

  Future<void> _reorderLinks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    setState(() => isLoading = true);

    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final Link item = links.removeAt(oldIndex);
      links.insert(newIndex, item);

      // Update order in Firestore
      final batch = FirebaseFirestore.instance.batch();

      for (var i = 0; i < links.length; i++) {
        final docRef = FirebaseFirestore.instance.collection('links').doc(links[i].id);
        batch.update(docRef, {'order': i});
      }

      await batch.commit();
    } catch (e) {
      print('Error reordering links: $e');
      // Reload links to ensure UI is in sync with database
      await _loadLinks();
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Copy link URL to clipboard
  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My LinkTree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLinkDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : links.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No links yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLinkDialog(),
              child: const Text('Add Your First Link'),
            ),
          ],
        ),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: links.length,
        onReorder: _reorderLinks,
        itemBuilder: (context, index) {
          final link = links[index];
          return Card(
            key: Key(link.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    link.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: link.description.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.description),
                      Text(
                        '${link.clickCount} clicks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                      : Text(
                    '${link.clickCount} clicks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => _copyToClipboard(link.url),
                        tooltip: 'Copy URL',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showLinkDialog(existingLink: link),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _launchUrl(link.url, link.id),
                        tooltip: 'Open Link',
                      ),
                    ],
                  ),
                  onTap: () => _launchUrl(link.url, link.id),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          link.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}