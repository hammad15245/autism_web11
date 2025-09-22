import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleAssignmentWidget extends StatefulWidget {
  final String childId;
  final String childName;

  const ModuleAssignmentWidget({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  State<ModuleAssignmentWidget> createState() => _ModuleAssignmentWidgetState();
}

class _ModuleAssignmentWidgetState extends State<ModuleAssignmentWidget> {
  List<String> _allModules = [];
  List<Map<String, dynamic>> _assignedModules = [];
  List<Map<String, dynamic>> _completedModules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final modulesSnapshot =
          await FirebaseFirestore.instance.collection('learningModules').get();

      final allModules = modulesSnapshot.docs
          .map((doc) => (doc.data()['title'] ?? doc.id).toString())
          .toList();

      final assignedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.childId)
          .collection('assignedModules')
          .get();

      final assignedModules = <Map<String, dynamic>>[];
      final completedModules = <Map<String, dynamic>>[];

      for (var doc in assignedSnapshot.docs) {
        final data = doc.data();
        if (data['isCompleted'] == true) {
          completedModules.add({...data, 'id': doc.id});
        } else {
          assignedModules.add({...data, 'id': doc.id});
        }
      }

      setState(() {
        _allModules = allModules;
        _assignedModules = assignedModules;
        _completedModules = completedModules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading modules: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignModule(String moduleName) async {
    if (widget.childId.isEmpty) return;

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.childId)
          .collection('assignedModules');

      final moduleDocId = moduleName.replaceAll(' ', '_').toLowerCase();
      final existingModule = await ref.doc(moduleDocId).get();
      if (existingModule.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$moduleName already assigned')));
        return;
      }

      await ref.doc(moduleDocId).set({
        'title': moduleName,
        'assignedAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'assignedBy': 'parent',
      });

      await _fetchModules();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$moduleName assigned successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning module: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Module Assignment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red))
        else ...[
          _buildModuleSection(
            'Available Modules',
            _allModules
                .where((module) =>
                    !_assignedModules.any((m) => m['title'] == module) &&
                    !_completedModules.any((m) => m['title'] == module))
                .toList(),
            assignable: true,
            onTap: _assignModule,
          ),
          const SizedBox(height: 16),
          _buildModuleSection(
            'Assigned Modules',
            _assignedModules,
            assignable: false,
          ),
          const SizedBox(height: 16),
          _buildModuleSection(
            'Completed Modules',
            _completedModules,
            assignable: false,
            isCompleted: true,
          ),
        ],
      ],
    );
  }

  Widget _buildModuleSection(String title, List items,
      {bool assignable = false,
      Function(String)? onTap,
      bool isCompleted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Text(
              assignable
                  ? 'No modules available'
                  : isCompleted
                      ? 'No modules completed yet'
                      : 'No modules assigned',
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final title = item is String ? item : item['title'];
              final id = item is String ? null : item['id'];
              final completed = item is String ? false : item['isCompleted'] ?? false;

              return InkWell(
                onTap: assignable && onTap != null
                    ? () => onTap(title.toString())
                    : null,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: completed
                          ? Colors.green[50]
                          : assignable
                              ? Colors.blue[50]
                              : Colors.orange[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: completed
                                    ? Colors.green
                                    : assignable
                                        ? Colors.blue
                                        : Colors.orange)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (completed)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else if (!assignable)
                              const Icon(Icons.hourglass_bottom,
                                  color: Colors.orange),
                            if (assignable)
                              const Icon(Icons.add, color: Colors.blue),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
      ],
    );
  }
}
