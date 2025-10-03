import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SubDepartmentManagementScreen extends StatefulWidget {
  const SubDepartmentManagementScreen({super.key});

  @override
  State<SubDepartmentManagementScreen> createState() =>
      _SubDepartmentManagementScreenState();
}

class _SubDepartmentManagementScreenState
    extends State<SubDepartmentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentNameController = TextEditingController();
  bool _isCreating = false;
  bool _isEditing = false;
  bool _isPasswordVisible = false;
  List<User> _subDepartmentHeads = [];
  User? _editingUser;

  @override
  void initState() {
    super.initState();
    _fetchSubDepartmentHeads();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubDepartmentHeads() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final domain = authProvider.user?.domain;
    if (domain != null) {
      final users = await authProvider.fetchSubDepartmentHeadsByDomain(domain);
      setState(() {
        _subDepartmentHeads = users;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _departmentNameController.clear();
    _editingUser = null;
    _isEditing = false;
    _isPasswordVisible = false;
    FocusScope.of(context).unfocus();
  }

  void _editUser(User user) {
    setState(() {
      _editingUser = user;
      _isEditing = true;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _departmentNameController.text = user.departmentName ?? '';
      _passwordController.clear();
      _isPasswordVisible = false;
    });
  }

  Future<void> _createOrUpdateSubDepartmentHead() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      if (_isEditing && _editingUser != null) {
        // Update existing user via PATCH
        success = await authProvider.updateSubDepartmentHead(
          userId: _editingUser!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.isEmpty
              ? 'unchanged'
              : _passwordController.text,
          departmentName: _departmentNameController.text.trim(),
        );
      } else {
        // Create new user
        success = await authProvider.createSubDepartmentHead(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _departmentNameController.text.trim(),
        );
      }

      setState(() {
        _isCreating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Sub-department head updated successfully'
                : 'Sub-department head created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _clearForm();
        await _fetchSubDepartmentHeads();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteSubDepartmentHead(user.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sub-department head deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchSubDepartmentHeads();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final domain = authProvider.user?.domain;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sub-Department Heads'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (domain != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Only emails from @$domain can be used to register sub-heads.'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Form Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isEditing ? Icons.edit : Icons.add,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing
                                ? 'Edit Sub-Department Head'
                                : 'Create New Sub-Department Head',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          if (domain != null &&
                              value.split('@').last.toLowerCase() !=
                                  domain.toLowerCase()) {
                            return 'Email must be from $domain';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: _isEditing
                              ? 'New Password (leave empty to keep current)'
                              : 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            tooltip: _isPasswordVisible
                                ? 'Hide password'
                                : 'Show password',
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (!_isEditing &&
                              (value == null || value.length < 6)) {
                            return 'Min 6 characters';
                          }
                          if (_isEditing &&
                              value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isCreating
                                  ? null
                                  : _createOrUpdateSubDepartmentHead,
                              child: _isCreating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(_isEditing ? 'Update' : 'Create'),
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isCreating ? null : _clearForm,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sub-Department Heads List
            Text(
              'Sub-Department Heads',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _subDepartmentHeads.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sub-department heads yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first sub-department head using the form above',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subDepartmentHeads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final head = _subDepartmentHeads[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              head.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(head.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(head.email),
                              if (head.departmentName != null)
                                Text(
                                  'Department: ${head.departmentName}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editUser(head),
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () => _deleteUser(head),
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
