import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/questionnaire.dart';
import '../providers/questionnaire_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart' as user_model;
import 'create_questionnaire_screen.dart';
import 'answer_questionnaire_screen.dart';
import 'response_detail_screen.dart';

class QuestionnaireListScreen extends StatefulWidget {
  const QuestionnaireListScreen({Key? key}) : super(key: key);

  // Static method to refresh questionnaire list from other screens
  static void refreshQuestionnaireList(BuildContext context) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    questionnaireProvider.fetchAllQuestionnaires(context);
    questionnaireProvider.fetchAllResponses(context);
  }

  @override
  _QuestionnaireListScreenState createState() =>
      _QuestionnaireListScreenState();
}

class _QuestionnaireListScreenState extends State<QuestionnaireListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    Future.delayed(Duration.zero, () {
      final questionnaireProvider =
          Provider.of<QuestionnaireProvider>(context, listen: false);
      questionnaireProvider.fetchAllQuestionnaires(context);
      questionnaireProvider.fetchAllResponses(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes visible
      final questionnaireProvider =
          Provider.of<QuestionnaireProvider>(context, listen: false);
      questionnaireProvider.fetchAllQuestionnaires(context);
      questionnaireProvider.fetchAllResponses(context);
    }
  }

  void _forceRefresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Questionnaires')),
        body: Center(child: Text('Please log in to view questionnaires')),
      );
    }

    // Different views based on user role
    bool isCSHead = user.role == user_model.UserRole.cyberSecurityHead;

    return Scaffold(
      key: ValueKey(_refreshKey),
      appBar: AppBar(
        title: Text('Questionnaires'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isCSHead ? 'All' : 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Drafts'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              final questionnaireProvider =
                  Provider.of<QuestionnaireProvider>(context, listen: false);
              await questionnaireProvider.fetchAllQuestionnaires(context);
              await questionnaireProvider.fetchAllResponses(context);
              _forceRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Questionnaires refreshed!')),
              );
            },
            tooltip: 'Refresh',
          ),
          if (isCSHead)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateQuestionnaireScreen(),
                  ),
                );
              },
              tooltip: 'Create Questionnaire',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All/Pending Questionnaires Tab
          _buildQuestionnaireList(
              context,
              questionnaireProvider,
              user_model.User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                departmentId: user.domain,
                departmentName: user.departmentName,
              ),
              isCSHead,
              isCSHead ? null : QuestionnaireStatus.published),

          // Completed Questionnaires Tab
          _buildQuestionnaireList(
              context,
              questionnaireProvider,
              user_model.User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                departmentId: user.domain,
                departmentName: user.departmentName,
              ),
              isCSHead,
              QuestionnaireStatus.completed),

          // Drafts Tab
          _buildDraftsList(
              context,
              questionnaireProvider,
              user_model.User(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                departmentId: user.domain,
                departmentName: user.departmentName,
              ),
              isCSHead),
        ],
      ),

      // FAB for creating new questionnaire (CS Head only)
      floatingActionButton: isCSHead
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateQuestionnaireScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
              tooltip: 'Create New Questionnaire',
            )
          : null,
    );
  }

  Widget _buildQuestionnaireList(
    BuildContext context,
    QuestionnaireProvider questionnaireProvider,
    user_model.User user,
    bool isCSHead,
    QuestionnaireStatus? status,
  ) {
    List<Questionnaire> questionnaires;

    if (isCSHead) {
      if (status != null) {
        // Filter by status for CS Head
        questionnaires = questionnaireProvider.questionnaires
            .where((q) => q.status == status && q.createdBy == user.email)
            .toList();
      } else {
        // All questionnaires for CS Head
        questionnaires = questionnaireProvider.questionnaires
            .where((q) => q.createdBy == user.email)
            .toList();
      }
    } else {
      // Sub-dept head sees questionnaires targeted to their department
      if (status != null) {
        questionnaires = questionnaireProvider.questionnaires
            .where((q) => q.departmentId == user.id && q.status == status)
            .toList();
      } else {
        questionnaires = questionnaireProvider.questionnaires
            .where((q) => q.departmentId == user.id)
            .toList();
      }
    }

    // Sort questionnaires by creation date (newest first)
    questionnaires.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (questionnaires.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              status == QuestionnaireStatus.published
                  ? 'No pending questionnaires'
                  : status == QuestionnaireStatus.completed
                      ? 'No completed questionnaires'
                      : 'No questionnaires available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            if (isCSHead)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateQuestionnaireScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Create New Questionnaire'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final questionnaireProvider =
            Provider.of<QuestionnaireProvider>(context, listen: false);
        await questionnaireProvider.fetchAllQuestionnaires(context);
        await questionnaireProvider.fetchAllResponses(context);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: questionnaires.length,
        itemBuilder: (context, index) {
          final questionnaire = questionnaires[index];
          return _buildQuestionnaireCard(
              context, questionnaire, isCSHead, user.id);
        },
      ),
    );
  }

  Widget _buildDraftsList(
    BuildContext context,
    QuestionnaireProvider questionnaireProvider,
    user_model.User user,
    bool isCSHead,
  ) {
    // For CS Head: show draft questionnaires
    // For Sub-dept Head: show questionnaires with saved draft responses

    List<Questionnaire> questionnaires = [];

    if (isCSHead) {
      // Get draft questionnaires
      questionnaires = questionnaireProvider.questionnaires
          .where((q) =>
              q.status == QuestionnaireStatus.draft &&
              q.createdBy == user.email)
          .toList();
    } else {
      // Get questionnaires with draft responses
      questionnaires = questionnaireProvider.questionnaires
          .where((q) =>
              q.departmentId == user.id &&
              questionnaireProvider.getDraftResponses(q.id, user.id) != null)
          .toList();
    }

    // Sort questionnaires by creation date (newest first)
    questionnaires.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (questionnaires.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drafts,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              isCSHead ? 'No draft questionnaires' : 'No saved draft responses',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final questionnaireProvider =
            Provider.of<QuestionnaireProvider>(context, listen: false);
        await questionnaireProvider.fetchAllQuestionnaires(context);
        await questionnaireProvider.fetchAllResponses(context);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: questionnaires.length,
        itemBuilder: (context, index) {
          final questionnaire = questionnaires[index];
          return _buildQuestionnaireCard(
              context, questionnaire, isCSHead, user.id,
              isDraft: true);
        },
      ),
    );
  }

  Widget _buildQuestionnaireCard(BuildContext context,
      Questionnaire questionnaire, bool isCSHead, String userId,
      {bool isDraft = false}) {
    // Get questionnaire status color
    Color statusColor;
    switch (questionnaire.status) {
      case QuestionnaireStatus.draft:
        statusColor = Colors.grey;
        break;
      case QuestionnaireStatus.published:
        statusColor = Colors.blue;
        break;
      case QuestionnaireStatus.completed:
        statusColor = Colors.green;
        break;
      case QuestionnaireStatus.archived:
        statusColor = Colors.orange;
        break;
    }

    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    final responses = isCSHead
        ? questionnaireProvider.responses
            .where((r) => r.questionnaireId == questionnaire.id)
            .toList()
        : [];

    // For completed questionnaires, check if there's a response from this user
    QuestionnaireResponse? userResponse;
    if (questionnaire.status == QuestionnaireStatus.completed && !isCSHead) {
      userResponse =
          questionnaireProvider.getLatestResponse(questionnaire.id, userId);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isCSHead) {
            if (questionnaire.status == QuestionnaireStatus.draft) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateQuestionnaireScreen(
                    questionnaireId: questionnaire.id,
                  ),
                ),
              );
            }
          } else {
            if (questionnaire.status == QuestionnaireStatus.published ||
                isDraft) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnswerQuestionnaireScreen(
                    questionnaireId: questionnaire.id,
                  ),
                ),
              );
            } else if (userResponse != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResponseDetailScreen(
                    responseId: userResponse!.id,
                  ),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      questionnaire.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withAlpha((0.5 * 255).toInt())),
                    ),
                    child: Text(
                      isDraft &&
                              !isCSHead &&
                              questionnaire.status ==
                                  QuestionnaireStatus.published
                          ? 'DRAFT RESPONSE'
                          : _getStatusText(questionnaire.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                questionnaire.description,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(questionnaire.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.format_list_numbered,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${questionnaire.questions.length} Questions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Show responses directly for CS Head
              if (isCSHead && questionnaire.status != QuestionnaireStatus.draft)
                ...responses.map((r) => Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Submitted at: ${r.submittedAt.toLocal().toString()}'),
                            const SizedBox(height: 4),
                            ...r.responses.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                      '${entry.key}: ${entry.value ?? "-"}'),
                                )),
                          ],
                        ),
                      ),
                    )),

              // Actions for Sub Department Head
              if (!isCSHead &&
                  questionnaire.status == QuestionnaireStatus.published)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnswerQuestionnaireScreen(
                                questionnaireId: questionnaire.id,
                              ),
                            ),
                          );
                        },
                        child: isDraft ? Text('Continue') : Text('Answer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDraft
                              ? Colors.amber
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isCSHead &&
                  questionnaire.status == QuestionnaireStatus.completed &&
                  userResponse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResponseDetailScreen(
                                responseId: userResponse!.id,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Responses'),
                      ),
                    ],
                  ),
                ),

              if (isCSHead)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (questionnaire.status == QuestionnaireStatus.draft)
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateQuestionnaireScreen(
                                      questionnaireId: questionnaire.id,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _publishQuestionnaire(context, questionnaire);
                              },
                              child: const Text('Publish'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                _deleteQuestionnaire(context, questionnaire);
                              },
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      if (questionnaire.status ==
                              QuestionnaireStatus.published ||
                          questionnaire.status == QuestionnaireStatus.completed)
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                _viewResponses(context, questionnaire);
                              },
                              child: const Text('Responses'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                _deleteQuestionnaire(context, questionnaire);
                              },
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Delete'),
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

  String _getStatusText(QuestionnaireStatus status) {
    switch (status) {
      case QuestionnaireStatus.draft:
        return 'DRAFT';
      case QuestionnaireStatus.published:
        return 'PENDING';
      case QuestionnaireStatus.completed:
        return 'COMPLETED';
      case QuestionnaireStatus.archived:
        return 'ARCHIVED';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _publishQuestionnaire(
      BuildContext context, Questionnaire questionnaire) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Questionnaire'),
        content: Text(
            'Are you sure you want to publish "${questionnaire.title}"? Once published, it will be visible to the target department.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Update questionnaire status
              final updatedQuestionnaire = questionnaire.copyWith(
                status: QuestionnaireStatus.published,
              );

              questionnaireProvider
                  .updateQuestionnaire(updatedQuestionnaire, context)
                  .then((success) {
                if (success) {
                  // Refresh the questionnaire list
                  questionnaireProvider.fetchAllQuestionnaires(context);
                  questionnaireProvider.fetchAllResponses(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Questionnaire published successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(questionnaireProvider.errorMessage ??
                            'Failed to publish questionnaire')),
                  );
                }
              });
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _deleteQuestionnaire(BuildContext context, Questionnaire questionnaire) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Questionnaire'),
        content: Text(
            'Are you sure you want to delete "${questionnaire.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Note: deleteQuestionnaire method doesn't exist in QuestionnaireProvider
              // For now, we'll just refresh the data
              questionnaireProvider.fetchAllQuestionnaires(context);
              questionnaireProvider.fetchAllResponses(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Questionnaire deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewResponses(BuildContext context, Questionnaire questionnaire) {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

    final responses = questionnaireProvider.responses
        .where((r) => r.questionnaireId == questionnaire.id)
        .toList();

    if (responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No responses found for this questionnaire.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResponseDetailScreen(
          responseId: responses
              .first.id, // Assuming the first response is representative
        ),
      ),
    );
  }
}
