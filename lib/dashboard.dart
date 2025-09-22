import 'package:autism_parent_web/controller/auth_controller.dart';
import 'package:autism_parent_web/widgets/custom_widget.dart';
import 'package:autism_parent_web/widgets/drawer.dart';
import 'package:autism_parent_web/widgets/module_assignment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';


class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final AuthController authController = Get.find<AuthController>();
  Map<String, dynamic>? childData;
  bool isLoading = true;
  String? errorMessage;
  String? _selectedChildId;
  
  Map<String, double> skillProgress = {
    "cognitive": 0.0,
    "learning": 0.0,
    "behavior": 0.0,
  };
  
  Map<String, double> moduleProgress = {};
  List<Map<String, dynamic>> recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (_selectedChildId == null) {
        setState(() {
          isLoading = false;
          errorMessage = "No child selected";
        });
        return;
      }

      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedChildId)
          .get();

      if (!childDoc.exists) {
        setState(() {
          isLoading = false;
          errorMessage = "Child data not found";
        });
        return;
      }

      // Fetch all modules to calculate progress
      await _fetchModuleProgress();
      
      // Calculate skill-based progress
      await _calculateSkillProgress();

      setState(() {
        childData = childDoc.data();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading child data: ${e.toString()}";
      });
    }
  }

  Future<void> _fetchModuleProgress() async {
    if (_selectedChildId == null) return;

    final modulesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_selectedChildId)
        .collection('progress')
        .get();

    moduleProgress.clear();
    recentActivities.clear();

    for (var moduleDoc in modulesSnapshot.docs) {
      if (moduleDoc.id == 'overview') continue;
      
      final moduleData = moduleDoc.data();
      double completionRate = 0.0;
      int completedQuizzes = 0;
      int totalQuizzes = 0;
      
      // Calculate module completion based on quizzes
      if (moduleData['quizzes'] is Map) {
        final quizzes = Map<String, dynamic>.from(moduleData['quizzes']);
        totalQuizzes = quizzes.length;
        
        quizzes.forEach((key, quizData) {
          if (quizData is Map && quizData['isCompleted'] == true) {
            completedQuizzes++;
            
            // Add to recent activities
            if (recentActivities.length < 5) {
              recentActivities.add({
                'module': moduleDoc.id,
                'quiz': key,
                'timestamp': quizData['lastAttempt'],
                'score': quizData['score'] ?? 0
              });
            }
          }
        });
      }
      
      if (totalQuizzes > 0) {
        completionRate = completedQuizzes / totalQuizzes;
      }
      
      moduleProgress[moduleDoc.id] = completionRate;
    }
    
    // Sort recent activities by timestamp
    recentActivities.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp;
      final bTime = b['timestamp'] as Timestamp;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _calculateSkillProgress() async {
    // Reset progress
    skillProgress = {
      "cognitive": 0.0,
      "learning": 0.0,
      "behavior": 0.0,
    };
    
    // Define which modules belong to which skill category
    final Map<String, List<String>> skillCategories = {
      "cognitive": ["ABC letters", "Add and Subtract", "counting", "Match", "Searching"],
      "learning": ["Birds", "home animals", "Unmixing search"],
      "behavior": ["bathing", "brushing teeth", "eating food", "going to bed", "Inhibiting"]
    };
    
    int cognitiveModules = 0;
    int learningModules = 0;
    int behaviorModules = 0;
    
    // Calculate average progress for each category
    moduleProgress.forEach((moduleName, progress) {
      if (skillCategories["cognitive"]!.contains(moduleName)) {
        skillProgress["cognitive"] = skillProgress["cognitive"]! + progress;
        cognitiveModules++;
      } else if (skillCategories["learning"]!.contains(moduleName)) {
        skillProgress["learning"] = skillProgress["learning"]! + progress;
        learningModules++;
      } else if (skillCategories["behavior"]!.contains(moduleName)) {
        skillProgress["behavior"] = skillProgress["behavior"]! + progress;
        behaviorModules++;
      }
    });
    
    // Calculate averages
    if (cognitiveModules > 0) {
      skillProgress["cognitive"] = skillProgress["cognitive"]! / cognitiveModules;
    }
    if (learningModules > 0) {
      skillProgress["learning"] = skillProgress["learning"]! / learningModules;
    }
    if (behaviorModules > 0) {
      skillProgress["behavior"] = skillProgress["behavior"]! / behaviorModules;
    }
  }

  // Function to delete child from Firebase
  Future<void> _deleteChild() async {
    if (_selectedChildId == null) return;

    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Child Account"),
          content: const Text("Are you sure you want to delete this child's account? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      // Delete child document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedChildId)
          .delete();

      // Also remove from parent's children list if you have that structure
      // final parentId = authController.userData.value?['uid'];
      // if (parentId != null) {
      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(parentId)
      //       .collection('children')
      //       .doc(_selectedChildId)
      //       .delete();
      // }

      // Reset the UI
      setState(() {
        _selectedChildId = null;
        childData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Child account deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting child: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double breakpoint = 800;

    return screenWidth < breakpoint ? _buildMobileLayout() : _buildDesktopLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontSize: 18)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SearchChildWidget(
                onChildSelected: (String childId) {
                  setState(() => _selectedChildId = childId);
                  _fetchChildData();
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSkillProgressSection(),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildChildInfoSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 250, child: CustomDrawer()),
          SizedBox(
            width: 300,
            child: SearchChildWidget(
              onChildSelected: (String childId) {
                setState(() => _selectedChildId = childId);
                _fetchChildData();
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildSkillProgressSection(),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildChildInfoSection(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillProgressSection() {
    return Column(
      children: [
        const Text(
          "Skill Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSkillProgressCircle("Cognitive", skillProgress["cognitive"] ?? 0.0, Colors.blue),
            _buildSkillProgressCircle("Learning", skillProgress["learning"] ?? 0.0, Colors.green),
            _buildSkillProgressCircle("Behavior", skillProgress["behavior"] ?? 0.0, Colors.orange),
          ],
        ),
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
          center: Text(
            "${(value * 100).toStringAsFixed(0)}%",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          progressColor: color,
          backgroundColor: Colors.grey[200]!,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildChildInfoSection() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    if (childData == null) {
      return const Center(child: Text("Select a child to view their progress", style: TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Profile Card with Delete Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (childData?['avatar'] != null &&
                            childData!['avatar'].toString().isNotEmpty)
                        ? NetworkImage(childData!['avatar'])
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(childData?['username'] ?? 'Unknown Child',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(childData?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                        Text('Age: ${childData?['age'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteChild,
                    tooltip: 'Delete Child Account',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Module Assignment Widget - ADDED HERE
          ModuleAssignmentWidget(
            childId: _selectedChildId!,
            childName: childData?['username'] ?? 'Your Child',
          ),
          
          const SizedBox(height: 20),
          
          // Module Progress Section
          const Text(
            "Module Progress",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildModuleProgressList(),
          
          const SizedBox(height: 20),
          
          // Recent Activities
          const Text(
            "Recent Activities",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildRecentActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildModuleProgressList() {
    if (moduleProgress.isEmpty) {
      return const Text("No module progress data available");
    }
    
    return Column(
      children: moduleProgress.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatModuleName(entry.key),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  value: entry.value,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    entry.value > 0.7 ? Colors.green : 
                    entry.value > 0.4 ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${(entry.value * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivitiesList() {
    if (recentActivities.isEmpty) {
      return const Text("No recent activities");
    }
    
    return Column(
      children: recentActivities.map((activity) {
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text("Completed ${_formatModuleName(activity['module'])} - ${activity['quiz']}"),
          subtitle: Text(
            "Score: ${activity['score']} - ${_formatTimestamp(activity['timestamp'])}",
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  String _formatModuleName(String moduleName) {
    // Convert snake_case or camelCase to Title Case
    return moduleName
        .replaceAllMapped(RegExp(r'^[a-z]|[A-Z]'), 
            (Match m) => m[0]!.toUpperCase())
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), 
            (Match m) => '${m[1]} ${m[2]}');
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}