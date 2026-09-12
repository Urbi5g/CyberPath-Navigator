import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_service.dart';

import 'stage_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final DashboardService dashboardService = DashboardService();

  int paths = 0;
  int users = 0;
  int stages = 0;
  bool loading = true;
  final TextEditingController _userSearchController =
  TextEditingController();

  String _userSearch = '';

  final List<_AdminMenuItem> _menuItems = const [
    _AdminMenuItem(title: 'Dashboard', icon: Icons.dashboard_outlined),
    _AdminMenuItem(title: 'Learning Paths', icon: Icons.route_outlined),
    _AdminMenuItem(title: 'Users', icon: Icons.people_outline),
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final p = await dashboardService.getLearningPathsCount();
      final u = await dashboardService.getUsersCount();
      final s = await dashboardService.getStagesCount();

      if (mounted) {
        setState(() {
          paths = p;
          users = u;
          stages = s;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isWide
          ? null
          : AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      drawer: isWide ? null : _buildDrawer(theme),
      body: Row(
        children: [
          if (isWide) _buildSidebar(theme),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildContent(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CyberPath\nAdmin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(theme, _menuItems[index], index);
                },
              ),
            ),
            _buildAdminAccount(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: theme.cardColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            const Text(
              'CyberPath Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(theme, _menuItems[index], index);
                },
              ),
            ),
            _buildAdminAccount(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(ThemeData theme, _AdminMenuItem item, int index) {
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        leading: Icon(
          item.icon,
          color: selected ? theme.colorScheme.primary : theme.iconTheme.color,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildAdminAccount(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administrator',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? 'Admin account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_selectedIndex) {
      case 1:
        return _buildLearningPaths(theme);
      case 2:
        return _buildUsersSection(theme);
      default:
        return _buildDashboard(theme);
    }
  }

  Widget _buildDashboard(ThemeData theme) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(
                theme,
                title: 'Dashboard',
                subtitle: 'Manage CyberPath Navigator content and users.',
              ),
              const SizedBox(height: 28),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('learning_paths')
                    .snapshots(),
                builder: (context, snapshot) {
                  final pathCount = snapshot.hasData
                      ? snapshot.data!.docs.length
                      : null;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 750 ? 3 : 1;

                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.4,
                        children: [
                          _buildStatCard(
                            theme,
                            title: 'Learning Paths',
                            value: pathCount?.toString() ?? (loading ? '...' : paths.toString()),
                            icon: Icons.route_outlined,
                          ),
                          _buildStatCard(
                            theme,
                            title: 'Users',
                            value: loading ? '...' : users.toString(),
                            icon: Icons.people_outline,
                          ),
                          _buildStatCard(
                            theme,
                            title: 'Stages',
                            value: loading ? '...' : stages.toString(),
                            icon: Icons.menu_book_outlined,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage the main learning content of the platform.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          theme,
                          icon: Icons.add_road,
                          title: 'Add Learning Path',
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                        ),
                        _buildActionButton(
                          theme,
                          icon: Icons.people_outline,
                          title: 'Manage Users',
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningPaths(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('learning_paths')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(
            theme,
            'Unable to load learning paths.\n${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(
                    theme,
                    title: 'Learning Paths',
                    subtitle: 'Create and manage learning paths for students.',
                    action: ElevatedButton.icon(
                      onPressed: _showAddPathDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Path'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (documents.isEmpty)
                    _buildEmptyState(
                      theme,
                      icon: Icons.route_outlined,
                      title: 'No learning paths yet',
                      message:
                      'Learning paths created by the administrator '
                          'will appear here.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: documents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final document = documents[index];

                        return _buildPathCard(
                          theme,
                          document.data(),
                          document.id,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddPathDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return const _AddLearningPathDialog();
      },
    );
    // تحديث الإحصائيات بعد الإغلاق
    loadDashboard();
  }

  Future<void> _showEditPathDialog(
      String pathId,
      Map<String, dynamic> data,
      ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _EditLearningPathDialog(pathId: pathId, initialData: data);
      },
    );
  }

  Widget _buildUsersSection(ThemeData theme) {

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),


      builder: (context, snapshot) {


        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Center(
            child: CircularProgressIndicator(),
          );

        }


        if (snapshot.hasError) {

          return Center(
            child: Text(
              snapshot.error.toString(),
            ),
          );

        }


        final allUsers =
            snapshot.data?.docs ?? [];



        final filteredUsers =
        allUsers.where((user) {


          final data = user.data();


          final name =
          (data['name'] ?? '')
              .toString()
              .toLowerCase();


          final email =
          (data['email'] ?? '')
              .toString()
              .toLowerCase();



          return name.contains(
            _userSearch.toLowerCase(),
          ) ||
              email.contains(
                _userSearch.toLowerCase(),
              );


        }).toList();





        return Column(

          children: [



            // شريط البحث

            TextField(

              controller:
              _userSearchController,


              decoration:
              InputDecoration(

                hintText:
                'Search users...',


                prefixIcon:
                const Icon(
                  Icons.search,
                ),


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(12),

                ),

              ),



              onChanged: (value) {


                setState(() {

                  _userSearch = value;

                });


              },

            ),



            const SizedBox(height: 16),




            Expanded(

              child: ListView.builder(

                itemCount:
                filteredUsers.length,


                itemBuilder:
                    (context, index) {



                  final data =
                  filteredUsers[index]
                      .data();



                  return Card(

                    margin:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),


                    child: ListTile(



                      leading: Row(

                        mainAxisSize:
                        MainAxisSize.min,


                        children: [



                          CircleAvatar(

                            radius: 15,

                            child:
                            Text(
                              '${index + 1}',
                            ),

                          ),



                          const SizedBox(
                            width: 8,
                          ),



                          const CircleAvatar(

                            child:
                            Icon(
                              Icons.person,
                            ),

                          ),


                        ],

                      ),




                      title: Text(

                        data['name'] ??
                            'No Name',


                        style:
                        const TextStyle(

                          fontWeight:
                          FontWeight.w600,

                        ),

                      ),




                      subtitle: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment.start,


                        children: [



                          Text(

                            'Level: ${data['level'] ?? '-'}',

                          ),



                          Text(

                            data['email'] ??
                                '',

                          ),



                          Text(

                            'Role: ${data['role'] ?? 'student'}',

                          ),



                        ],

                      ),





                      trailing:

                      DropdownButton<String>(

                        value:
                        data['role'] ??
                            'student',


                        items: const [


                          DropdownMenuItem(

                            value:
                            'student',

                            child:
                            Text(
                              'Student',
                            ),

                          ),



                          DropdownMenuItem(

                            value:
                            'admin',

                            child:
                            Text(
                              'Admin',
                            ),

                          ),


                        ],



                        onChanged:
                            (value) async {


                          if (value == null)
                            return;



                          await FirebaseFirestore
                              .instance
                              .collection('users')
                              .doc(
                            filteredUsers[index]
                                .id,
                          )
                              .update({

                            'role':
                            value,

                          });



                        },

                      ),


                    ),

                  );


                },

              ),

            ),

          ],

        );


      },

    );

  }  Widget _buildPageHeader(
      ThemeData theme, {
        required String title,
        required String subtitle,
        Widget? action,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatCard(
      ThemeData theme, {
        required String title,
        required String value,
        required IconData icon,
      }) {
    return _buildSectionCard(
      theme,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard(
      ThemeData theme,
      Map<String, dynamic> data,
      String pathId,
      ) {
    final title = data['title']?.toString() ?? 'Untitled Path';
    final description = data['description']?.toString() ?? '';
    final level = data['level']?.toString() ?? '—';
    final interest = data['interest']?.toString() ?? '—';

    return _buildSectionCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          theme,
                          Icons.signal_cellular_alt_outlined,
                          level,
                        ),
                        _buildInfoChip(theme, Icons.work_outline, interest),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('learning_paths')
                              .doc(pathId)
                              .collection('stages')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _buildInfoChip(
                                theme,
                                Icons.menu_book_outlined,
                                'Stages —',
                              );
                            }

                            final stageCount = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;

                            return _buildInfoChip(
                              theme,
                              Icons.menu_book_outlined,
                              '$stageCount Stages',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StageManagementScreen(
                        pathId: pathId,
                        pathTitle: title,
                      ),
                    ),
                  );
                  // تحديث إحصائية المراحل بعد العودة
                  loadDashboard();
                },
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Manage Stages'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _showEditPathDialog(pathId, data);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Path'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      ThemeData theme, {
        required IconData icon,
        required String title,
        required VoidCallback onPressed,
      }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.20)),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, {
        required IconData icon,
        required String title,
        required String message,
      }) {
    return _buildSectionCard(
      theme,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Icon(icon, size: 55, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: _buildSectionCard(
        theme,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _AddLearningPathDialog extends StatefulWidget {
  const _AddLearningPathDialog();

  @override
  State<_AddLearningPathDialog> createState() => _AddLearningPathDialogState();
}

class _AddLearningPathDialogState extends State<_AddLearningPathDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String _selectedLevel = 'Beginner';
  String _selectedInterest = 'SOC Analyst';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _createPath() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a path title.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session not found. Please log in again.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('learning_paths').add({
        'title': title,
        'description': description,
        'level': _selectedLevel,
        'interest': _selectedInterest,
        'totalStages': 0,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning path created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create learning path: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Learning Path'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Path title',
                  hintText: 'Example: SOC Analyst Fundamentals',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what the student will learn.',
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                  DropdownMenuItem(
                    value: 'Intermediate',
                    child: Text('Intermediate'),
                  ),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedLevel = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedInterest,
                decoration: const InputDecoration(labelText: 'Interest'),
                items: const [
                  DropdownMenuItem(
                    value: 'SOC Analyst',
                    child: Text('SOC Analyst'),
                  ),
                  DropdownMenuItem(
                    value: 'Penetration Tester',
                    child: Text('Penetration Tester'),
                  ),
                  DropdownMenuItem(
                    value: 'Digital Forensics',
                    child: Text('Digital Forensics'),
                  ),
                  DropdownMenuItem(
                    value: 'Security Engineer',
                    child: Text('Security Engineer'),
                  ),
                  DropdownMenuItem(
                    value: 'Cloud Security',
                    child: Text('Cloud Security'),
                  ),
                  DropdownMenuItem(
                    value: 'Incident Responder',
                    child: Text('Incident Responder'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedInterest = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _createPath,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Create Path'),
        ),
      ],
    );
  }
}

class _EditLearningPathDialog extends StatefulWidget {
  final String pathId;
  final Map<String, dynamic> initialData;

  const _EditLearningPathDialog({
    required this.pathId,
    required this.initialData,
  });

  @override
  State<_EditLearningPathDialog> createState() =>
      _EditLearningPathDialogState();
}

class _EditLearningPathDialogState extends State<_EditLearningPathDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late String _selectedLevel;
  late String _selectedInterest;

  bool _isSaving = false;

  final List<String> _levels = const ['Beginner', 'Intermediate', 'Advanced'];

  final List<String> _interests = const [
    'SOC Analyst',
    'Penetration Tester',
    'Digital Forensics',
    'Security Engineer',
    'Cloud Security',
    'Incident Responder',
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialData['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.initialData['description']?.toString() ?? '',
    );

    final savedLevel = widget.initialData['level']?.toString();

    final savedInterest = widget.initialData['interest']?.toString();

    _selectedLevel = _levels.contains(savedLevel) ? savedLevel! : 'Beginner';

    _selectedInterest = _interests.contains(savedInterest)
        ? savedInterest!
        : 'SOC Analyst';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _updatePath() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a path title.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('learning_paths')
          .doc(widget.pathId)
          .update({
        'title': title,
        'description': description,
        'level': _selectedLevel,
        'interest': _selectedInterest,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning path updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError('Failed to update learning path: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Learning Path'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Path title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: _levels
                    .map(
                      (level) =>
                      DropdownMenuItem(value: level, child: Text(level)),
                )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedLevel = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedInterest,
                decoration: const InputDecoration(labelText: 'Interest'),
                items: _interests
                    .map(
                      (interest) => DropdownMenuItem(
                    value: interest,
                    child: Text(interest),
                  ),
                )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedInterest = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _updatePath,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _AdminMenuItem {
  final String title;
  final IconData icon;

  const _AdminMenuItem({required this.title, required this.icon});
}