import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final CollectionReference _mainCollection = _firestore.collection('firm');

class Database {
  static String? userUid;
  static String? tempUId;

  static Future<void> addUserNoKeyNot({
    required String userName,
    required String password,
    required String position,
    required bool status,
  }) async {
    DocumentReference documentReferencer =
        _mainCollection.doc(userUid).collection('company').doc();

    Map<String, dynamic> data = <String, dynamic>{
      "userName": userName,
      "password": password,
      "position": position,
      "status": status
    };

    await documentReferencer
        .set(data)
        .whenComplete(() => 'print("New user added to the database")')
        .catchError((e) => 'print(e)');
  }

  static Future<bool> newUserNot({
    required String userName,
    required String password,
    required String position,
    required bool status,
  }) async {
    DocumentReference documentReferencer =
        _mainCollection.doc(userUid).collection('company').doc(userName);

    DateTime atDate = DateTime.now();
    Map<String, dynamic> data = <String, dynamic>{
      "userName": userName,
      "password": password,
      "position": position,
      "status": status,
      "atDate": atDate.toString(),
    };

    await documentReferencer
        .set(data)
        .whenComplete(() => 'print("New user added to the database")')
        .catchError((e) => 'print(e)');
    return true;
  }

  static Future<void> addItemC({
    // required String name,
    // required String server,
    required String url,
    // required bool status,
    // required String dataName,
  }) async {
    // DocumentReference documentReferencer =
    //     _mainCollection.doc(userUid).collection('company').doc(tempUId);

    DocumentReference documentReferencerF = _mainCollection.doc(tempUId);

    // DocumentReference documentReferencerC =
    //     _mainCollection.doc(tempUId).collection('company').doc('admin');

    // Map<String, dynamic> data = <String, dynamic>{
    //   "name": name,
    //   "server": server,
    //   "url": url,
    //   "status": status
    // };

    // await documentReferencer
    //     .set(data)
    //     .whenComplete(() => print("New firm added to the database"))
    //     .catchError((e) => print(e));

    Map<String, dynamic> dataF = <String, dynamic>{
      // "name": name,
      // "db": dataName,
      "url": url //,
      // "active": status
    };

    // DateTime atDate = DateTime.now();
    // Map<String, dynamic> dataC = <String, dynamic>{
    //   "userName": "admin",
    //   "password": "admin",
    //   "position": "Admin",
    //   "status": status,
    //   "atDate": atDate.toString(),
    // };

    await documentReferencerF
        .set(dataF)
        .whenComplete(() => 'print("new firm added")')
        .catchError((e) => 'print(e)');

    // await documentReferencerC
    //     .set(dataC)
    //     .whenComplete(() => print("New firm added to the database"))
    //     .catchError((e) => print(e));
  }

  static Future<void> updateUserNot({
    required String userName,
    required String password,
    required bool status,
    required String position,
    required String docId,
  }) async {
    DocumentReference documentReferencer =
        _mainCollection.doc(userUid).collection('company').doc(docId);

    Map<String, dynamic> data = <String, dynamic>{
      "userName": userName,
      "password": password,
      "status": status,
      "position": position,
    };

    await documentReferencer
        .update(data)
        .whenComplete(() => 'print("Note item updated in the database")')
        .catchError((e) => 'print(e)');
  }

  static Future<void> updateFirm({
    // required String name,
    // required String server,
    required String url,
    // required bool status,
    // required String dataName,
    required String docId,
  }) async {
    // DocumentReference documentReferencer =
    //     _mainCollection.doc(userUid).collection('company').doc(docId);

    DocumentReference documentReferencerF = _mainCollection.doc(docId);

    // Map<String, dynamic> data = <String, dynamic>{
    //   "name": name,
    //   "server": server,
    //   "url": url,
    //   "status": status
    // };

    Map<String, dynamic> dataF = <String, dynamic>{
      // "name": name,
      // "db": dataName,
      "url": url //,
      // "active": status
    };

    // await documentReferencer
    //     .update(data)
    //     .whenComplete(() => print("Company updated in the database"))
    //     .catchError((e) => print(e));

    await documentReferencerF
        .update(dataF)
        .whenComplete(() => 'print("Firm  updated in the database")')
        .catchError((e) => 'print(e)');
  }

  static Stream<QuerySnapshot> readItems() {
    CollectionReference notesItemCollection = _mainCollection;
    // _mainCollection.doc(userUid).collection('company');

    return notesItemCollection.snapshots();
  }

  static Stream<QuerySnapshot> readUserListNot({required String uId}) {
    CollectionReference notesItemCollection =
        _mainCollection.doc(uId).collection('company');

    return notesItemCollection.snapshots();
  }

  static Stream<DocumentSnapshot> readItemsFirm() {
    DocumentReference notesItemCollection = _mainCollection.doc(userUid);

    return notesItemCollection.snapshots();
  }

  static Stream<DocumentSnapshot> readItemsFirmDetailsNot(
      {required String uId}) {
    DocumentReference notesItemCollection = _mainCollection.doc(uId);

    return notesItemCollection.snapshots();
  }

  static Stream<QuerySnapshot> readItemsC() {
    CollectionReference notesItemCollection = _mainCollection;
    // _mainCollection.doc(userUid).collection('company');

    return notesItemCollection.snapshots();
  }

  static Future<void> deleteFirm({
    required String docId,
  }) async {
    // DocumentReference documentReferencer =
    //     _mainCollection.doc(userUid).collection('company').doc(docId);

    DocumentReference documentReferencerF = _mainCollection.doc(docId);

    // await documentReferencer
    //     .delete()
    //     .whenComplete(() => print('Firm item deleted from the database'))
    //     .catchError((e) => print(e));

    await documentReferencerF
        .delete()
        .whenComplete(() => 'print(FirmData item deleted from the database)')
        .catchError((e) => 'print(e)');
  }

  static Future<void> deleteUserNot({
    required String docId,
  }) async {
    DocumentReference documentReferencer =
        _mainCollection.doc(userUid).collection('company').doc(docId);

    await documentReferencer
        .delete()
        .whenComplete(() => 'print("Note item deleted from the databas")')
        .catchError((e) => 'print(e)');
  }

  static Stream<DocumentSnapshot> loginUser({required String docId}) {
    return _mainCollection.doc(userUid).snapshots();
  }

  static Future<bool> ifUserExistNot({
    required String docId,
  }) async {
    DocumentReference qs =
        _mainCollection.doc(userUid).collection('company').doc(docId);
    DocumentSnapshot snap = await qs.get();

    if (snap.exists) {
      return true;
    } else {
      return false;
    }
  }
}
