import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cyberpath_curriculum.dart';

/// Creates/refreshes only the curriculum documents owned by the currently
/// signed-in administrator. Existing documents created by other users are
/// never modified.
class MyCurriculumSeeder {
  static const String seedVersion = 'cyberpath_v2';

  static Future<void> ensureForCurrentAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final owned = await firestore
        .collection('learning_paths')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    final managed = owned.docs.where((doc) {
      final version = doc.data()['seedVersion']?.toString();
      return version == 'cyberpath_v1' || version == seedVersion;
    }).toList();

    final expectedTitles = CyberPathCurriculum.templates
        .map((item) => item['title'].toString())
        .toSet();

    final currentManagedTitles = managed
        .map((doc) => doc.data()['title']?.toString() ?? '')
        .toSet();

    // Already complete: do nothing. This prevents recreation of documents,
    // which also preserves student progress and existing document IDs.
    if (managed.length == expectedTitles.length &&
        currentManagedTitles.containsAll(expectedTitles) &&
        managed.every(
          (doc) => doc.data()['seedVersion']?.toString() == seedVersion,
        )) {
      return;
    }

    // Remove only the old curriculum documents created by this admin.
    // Manually created paths and paths owned by other admins are untouched.
    for (final path in managed) {
      await _deletePathTree(path.reference);
    }

    for (final template in CyberPathCurriculum.templates) {
      await _createPathTree(
        firestore: firestore,
        ownerUid: user.uid,
        template: template,
      );
    }
  }

  static Future<void> _deletePathTree(
    DocumentReference<Map<String, dynamic>> pathRef,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final stages = await pathRef.collection('stages').get();

    for (final stage in stages.docs) {
      final quizzes = await stage.reference.collection('quizzes').get();

      for (final quiz in quizzes.docs) {
        final questions =
            await quiz.reference.collection('questions').get();
        await _deleteRefs(
          questions.docs.map((doc) => doc.reference),
        );
        await quiz.reference.delete();
      }

      await stage.reference.delete();
    }

    await pathRef.delete();
  }

  static Future<void> _deleteRefs(
    Iterable<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    final list = refs.toList();

    for (var start = 0; start < list.length; start += 450) {
      final end = (start + 450 < list.length) ? start + 450 : list.length;
      final batch = FirebaseFirestore.instance.batch();

      for (final ref in list.sublist(start, end)) {
        batch.delete(ref);
      }

      await batch.commit();
    }
  }

  static Future<void> _createPathTree({
    required FirebaseFirestore firestore,
    required String ownerUid,
    required Map<String, dynamic> template,
  }) async {
    final pathRef = firestore.collection('learning_paths').doc();

    final stages =
        (template['stages'] as List).cast<Map<String, dynamic>>();

    final pathBatch = firestore.batch();

    pathBatch.set(pathRef, {
      'title': template['title'],
      'description': template['description'],
      'level': template['level'],
      'interest': template['interest'],
      'totalStages': stages.length,
      'createdBy': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'seedVersion': seedVersion,
    });

    for (final stage in stages) {
      final stageRef = pathRef.collection('stages').doc();

      pathBatch.set(stageRef, {
        'title': stage['title'],
        'description': stage['description'],
        'order': stage['order'],
        'xp': stage['xp'],
        'duration': stage['duration'],
        'estimatedMinutes': stage['estimatedMinutes'],
        'difficulty': stage['difficulty'],
        'topics': stage['topics'],
        'learningObjectives': stage['learningObjectives'],
        'lessons': stage['lessons'],
        'resources': stage['resources'],
        'courses': stage['courses'],
        'platforms': stage['platforms'],
        'additionalLinks': stage['additionalLinks'],
        'seedKey':
            '${seedVersion}_${_slug(template['title'].toString())}_stage_${stage['order']}',
        'seedVersion': seedVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final quizRef = stageRef.collection('quizzes').doc();

      pathBatch.set(quizRef, {
        'title': '${stage['title']} Knowledge Check',
        'description':
            'Short assessment covering the core concepts of ${stage['title']}.',
        'totalQuestions': 4,
        'seedKey':
            '${seedVersion}_${_slug(template['title'].toString())}_stage_${stage['order']}_quiz',
        'seedVersion': seedVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final topics = (stage['topics'] as List).cast<String>();
      final questions = _questionsForStage(
        stage['title'].toString(),
        topics,
      );

      for (var i = 0; i < questions.length; i++) {
        final questionRef = quizRef.collection('questions').doc();

        pathBatch.set(questionRef, {
          'question': questions[i]['question'],
          'options': questions[i]['options'],
          'correctAnswer': questions[i]['correctAnswer'],
          'points': 1,
          'seedKey':
              '${seedVersion}_${_slug(template['title'].toString())}_stage_${stage['order']}_q_${i + 1}',
          'seedVersion': seedVersion,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await pathBatch.commit();
  }

  static List<Map<String, dynamic>> _questionsForStage(
    String stageTitle,
    List<String> topics,
  ) {
    final primary = topics.isNotEmpty ? topics.first : stageTitle;
    final secondary = topics.length > 1 ? topics[1] : stageTitle;

    return [
      {
        'question': 'Which topic is directly covered in "$stageTitle"?',
        'options': [
          primary,
          'Graphic design',
          'Video editing',
          'Game development',
        ],
        'correctAnswer': 0,
      },
      {
        'question': 'Which approach best supports the goals of "$stageTitle"?',
        'options': [
          'Apply the concepts in an authorized lab and document the result.',
          'Disable security controls before testing.',
          'Reuse the same password everywhere.',
          'Ignore evidence and logs.',
        ],
        'correctAnswer': 0,
      },
      {
        'question': 'Which concept is also relevant to this stage?',
        'options': [
          secondary,
          'Unrelated UI animation',
          'Photo editing',
          'Audio mastering',
        ],
        'correctAnswer': 0,
      },
      {
        'question':
            'What should a security learner prioritize when practicing "$stageTitle"?',
        'options': [
          'Ethical scope, evidence, and repeatable procedures.',
          'Testing random third-party systems without permission.',
          'Deleting logs after every exercise.',
          'Skipping documentation.',
        ],
        'correctAnswer': 0,
      },
    ];
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
