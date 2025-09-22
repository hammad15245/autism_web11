import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class SearchChildWidget extends StatefulWidget {
  final Function(String)? onChildSelected;
  final bool showAttachButton; // Add this to control button visibility

  const SearchChildWidget({super.key, this.onChildSelected, this.showAttachButton = true});

  @override
  State<SearchChildWidget> createState() => _SearchChildWidgetState();
}

class _SearchChildWidgetState extends State<SearchChildWidget> {
  final TextEditingController _childIdController = TextEditingController();
  bool _isLoading = false;
  String _message = "";
  String? _attachedChildId;
  List<String> _attachedChildren = []; // Store multiple children

  @override
  void initState() {
    super.initState();
    _loadAttachedChildren();
  }

  Future<void> _loadAttachedChildren() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) return;

    try {
      final parentDoc = await FirebaseFirestore.instance
          .collection("parents")
          .doc(parentUid)
          .get();

      if (parentDoc.exists && parentDoc.data()?['children'] != null) {
        setState(() {
          _attachedChildren = List<String>.from(parentDoc.data()?['children'] ?? []);
          if (_attachedChildren.isNotEmpty) {
            _attachedChildId = _attachedChildren.first;
            // Auto-select the first child
            if (widget.onChildSelected != null) {
              widget.onChildSelected!(_attachedChildId!);
            }
          }
        });
      }
    } catch (e) {
      print("Error loading attached children: $e");
    }
  }

  Future<void> _attachChild() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    final childUniqueId = _childIdController.text.trim();

    if (childUniqueId.isEmpty) {
      setState(() => _message = "Please enter a Child ID.");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where("uniqueId", isEqualTo: childUniqueId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _message = "Child not found. Please check the ID.";
          _isLoading = false;
        });
        return;
      }

      final childDoc = query.docs.first;
      final childUid = childDoc.id;
      final childData = childDoc.data();

      // Update parent document with child reference
      await FirebaseFirestore.instance
          .collection("parents")
          .doc(parentUid)
          .set({
        "children": FieldValue.arrayUnion([childUid]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection("users")
          .doc(childUid)
          .set({
        "parentId": parentUid,
      }, SetOptions(merge: true));

      setState(() {
        _attachedChildren.add(childUid);
        _attachedChildId = childUid;
        _message = "Child successfully linked! ✅\n"
                   "Name: ${childData['username'] ?? 'Unknown'}\n"
                   "Age: ${childData['age'] ?? 'N/A'}";
        _isLoading = false;
      });

      if (widget.onChildSelected != null) {
        widget.onChildSelected!(childUid);
      }

    } catch (e) {
      setState(() {
        _message = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _selectChild(String childId) {
    setState(() {
      _attachedChildId = childId;
    });
    if (widget.onChildSelected != null) {
      widget.onChildSelected!(childId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, 
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          if (_attachedChildren.isNotEmpty) ...[
            const Text(
              "Your Children:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10,),
            ..._attachedChildren.map((childId) => ListTile(
              leading: const Icon(Icons.child_care, size: 20),
              title: Text(
                "Child ${_attachedChildren.indexOf(childId) + 1}",
                style: TextStyle(
                  fontWeight: _attachedChildId == childId 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              onTap: () => _selectChild(childId),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 20,
            )).toList(),
            const Divider(height: 30),
          ],

          if (widget.showAttachButton) ...[
            const Text(
              "Add New Child:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _childIdController,
              decoration: InputDecoration(
                hintText: "Enter Child ID",
                prefixIcon: const Icon(Icons.search, color: Colors.teal, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _attachChild(),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _attachChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text("Attach", style: TextStyle(fontSize: 14)),
                    ),
                  ),
            const SizedBox(height: 10),
          ],

          // Message
          if (_message.isNotEmpty)
            Text(
              _message,
              style: TextStyle(
                fontSize: 12,
                color: _message.contains("successfully") || _message.contains("✅")
                    ? Colors.green[700]
                    : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _childIdController.dispose();
    super.dispose();
  }
}

class ChildInfoWidget extends StatelessWidget {
  final String uid; // unique id of child

  const ChildInfoWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("No child data found");
        }

        var data = snapshot.data!;
        String username = data["username"] ?? "Unknown";
        String avatarPath = data["avatarPath"] ?? "assets/default.png"; // fallback
        int score = data["score"] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(avatarPath),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Score: $score", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
