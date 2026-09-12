import 'package:cloud_firestore/cloud_firestore.dart';


class DashboardService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  Future<int> getLearningPathsCount() async {

    final snapshot =
    await _firestore
        .collection('learning_paths')
        .get();

    return snapshot.docs.length;
  }


  Future<int> getUsersCount() async {

    final snapshot =
    await _firestore
        .collection('users')
        .get();

    return snapshot.docs.length;
  }


  Future<int> getStagesCount() async {

    final snapshot =
    await _firestore
        .collectionGroup('stages')
        .get();

    return snapshot.docs.length;
  }

}