import 'package:autism_parent_web/widgets/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:autism_parent_web/controller/auth_controller.dart';
import 'package:autism_parent_web/widgets/module_assignment.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final AuthController authController = Get.find<AuthController>();

  String? _selectedClassId;
  String? _selectedChildId;
  Map<String, dynamic>? childData;
  Map<String, double> moduleProgress = {};
  Map<String, double> skillProgress = {
    "cognitive": 0.0,
    "learning": 0.0,
    "behavior": 0.0,
  };
  List<Map<String, dynamic>> recentActivities = [];

  Future<void> createClass(String className) async {
    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        Get.snackbar("Error", "No teacher logged in.");
        return;
      }

      final teacherDocRef =
          FirebaseFirestore.instance.collection('teachers').doc(teacherId);

      await teacherDocRef.collection('classes').add({
        'name': className,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Class '$className' created successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to create class: $e");
    }
  }

  Future<void> addChildToClass(String classId, Map<String, dynamic> childData) async {
    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) return;

      final classDocRef = FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('classes')
          .doc(classId);

      await classDocRef.collection('children').add(childData);
      Get.snackbar("Success", "Child added to class");
    } catch (e) {
      Get.snackbar("Error", "Failed to add child: $e");
    }
  }

  void _createNewClass() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create New Class"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter class name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await createClass(name);
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _addChildDialog(String classId) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Child"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Child Name")),
            const SizedBox(height: 8),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Child Email")),
            const SizedBox(height: 8),
            TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await addChildToClass(classId, {
                  "username": nameController.text,
                  "email": emailController.text,
                  "age": ageController.text,
                  "createdAt": FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const breakpoint = 800;
    return screenWidth < breakpoint ? _buildMobileLayout() : _buildDesktopLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewClass,
            tooltip: "Create New Class",
          ),
        ],
      ),
      body: _buildClassGrid(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          const CustomDrawer(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Teacher Dashboard",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _createNewClass,
                        icon: const Icon(Icons.add),
                        label: const Text("New Class"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildClassGrid()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassGrid() {
    final teacherId = FirebaseAuth.instance.currentUser?.uid;
    if (teacherId == null) return const Center(child: Text("No teacher logged in"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('classes')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No classes created yet."));

        final classes = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200
                ? 4
                : MediaQuery.of(context).size.width > 800
                    ? 3
                    : 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classId = classes[index].id;
            final data = classes[index].data() as Map<String, dynamic>;
            final className = data['name'] ?? "Unnamed Class";

            return GestureDetector(
              onTap: () => _openClassDetails(classId, className),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(2, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.class_, size: 48, color: Colors.blueAccent),
                    const SizedBox(height: 12),
                    Text(className, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openClassDetails(String classId, String className) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Class: $className", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () => _addChildDialog(classId),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChildrenList(classId),
              if (_selectedChildId != null) ...[
                const SizedBox(height: 20),
                ModuleAssignmentWidget(childId: _selectedChildId!, childName: childData?['username'] ?? "Student"),
                const SizedBox(height: 20),
                _buildSkillProgressSection(),
                const SizedBox(height: 20),
                _buildModuleProgressList(),
                const SizedBox(height: 20),
                _buildRecentActivitiesList(),
              ]
            ]),
          );
        },
      ),
    );
  }

  Widget _buildChildrenList(String classId) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('classes')
          .doc(classId)
          .collection('children')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text("No children in this class yet.");
        return Wrap(
          runSpacing: 10,
          children: snapshot.data!.docs.map((childDoc) {
            final data = childDoc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(data['username'] ?? "Unnamed"),
              subtitle: Text(data['email'] ?? ""),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  _selectedChildId = childDoc.id;
                  childData = data;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSkillProgressSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSkillProgressCircle("Cognitive", skillProgress["cognitive"] ?? 0.0, Colors.blue),
        _buildSkillProgressCircle("Learning", skillProgress["learning"] ?? 0.0, Colors.green),
        _buildSkillProgressCircle("Behavior", skillProgress["behavior"] ?? 0.0, Colors.orange),
      ],
    );
  }

  Widget _buildSkillProgressCircle(String title, double value, Color color) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 10,
          percent: value.clamp(0, 1),
          center: Text("${(value * 100).toStringAsFixed(0)}%", style: TextStyle(color: color)),
          progressColor: color,
          backgroundColor: Colors.grey[200]!,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModuleProgressList() {
    if (moduleProgress.isEmpty) return const Text("No module progress data available");
    return Column(
      children: moduleProgress.entries
          .map((e) => ListTile(
                leading: const Icon(Icons.book, color: Colors.indigo),
                title: Text(e.key),
                trailing: Text("${(e.value * 100).toStringAsFixed(0)}%"),
              ))
          .toList(),
    );
  }

  Widget _buildRecentActivitiesList() {
    if (recentActivities.isEmpty) return const Text("No recent activities");
    return Column(
      children: recentActivities
          .map((activity) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text("Completed ${activity['module']} - ${activity['quiz']}"),
              ))
          .toList(),
    );
  }
}
