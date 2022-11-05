import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/ui/edit_screen.dart';
import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';

class ItemListC extends StatelessWidget {
  const ItemListC({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Database.readItemsC(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        } else if (snapshot.hasData || snapshot.data != null) {
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // var noteInfo = snapshot.data!.docs[index].data()!;
              String docID = snapshot.data!.docs[index].id;
              // String name = snapshot.data!.docs[index]['name'];
              // String server = snapshot.data!.docs[index]['server'];
              // bool status = snapshot.data!.docs[index]['status'];
              String url = snapshot.data!.docs[index]['url'];

              return Ink(
                decoration: BoxDecoration(
                  color: firebaseGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  // onTap: () => Database.readItemsFirmDetails(uId: docID)
                  //     .first
                  //     .then<dynamic>((DocumentSnapshot snapshot) async {
                  //   if (snapshot.data() != null) {
                  //     // String db = snapshot['db'];
                  //     // snapshot['active'];
                  //     // snapshot['name'];
                  //     snapshot['url'];
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditScreenC(
                        currentCode: docID,
                        // currentDb: db,
                        // currentName: name,
                        // currentServerName: server,
                        currentUrl: url,
                        // currentStatus: status,
                        documentId: docID,
                      ),
                    ),
                  ),
                  //   } else {
                  //     Navigator.of(context).push(
                  //       MaterialPageRoute(
                  //         builder: (context) => EditScreenC(
                  //           currentCode: docID,
                  //           // currentDb: '',
                  //           // currentName: name,
                  //           // currentServerName: server,
                  //           currentUrl: url,
                  //           // currentStatus: status,
                  //           documentId: docID,
                  //         ),
                  //       ),
                  //     );
                  //   }
                  // }),
                  title: Text(
                    docID,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        }

        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              firebaseOrange,
            ),
          ),
        );
      },
    );
  }
}

// class ItemList extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: Database.readItems(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         } else if (snapshot.hasData || snapshot.data != null) {
//           return ListView.separated(
//             separatorBuilder: (context, index) => SizedBox(height: 16.0),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               // var noteInfo = snapshot.data!.docs[index].data()!;
//               String docID = snapshot.data!.docs[index].id;
//               String userName = snapshot.data!.docs[index]['userName'];
//               String password = snapshot.data!.docs[index]['password'];
//               String position = snapshot.data!.docs[index]['position'];
//               bool status = snapshot.data!.docs[index]['status'];

//               return Ink(
//                 decoration: BoxDecoration(
//                   color: firebaseGrey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//                 child: ListTile(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   onTap: () => Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => EditScreen(
//                         currentName: userName,
//                         currentPosition: position,
//                         currentPassword: password,
//                         currentStatus: status,
//                         documentId: docID,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     userName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     position,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   trailing: Text(
//                     status ? 'Status:Running' : 'Status:Trial',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         color: status ? green[900] : red[900],
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               );
//             },
//           );
//         }

//         return Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(
//               firebaseOrange,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class ItemUserList extends StatelessWidget {
//   final String uId;
//   ItemUserList({required this.uId});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: Database.readUserList(uId: uId),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         } else if (snapshot.hasData || snapshot.data != null) {
//           return ListView.separated(
//             separatorBuilder: (context, index) => SizedBox(height: 16.0),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               // var noteInfo = snapshot.data!.docs[index].data()!;
//               String docID = snapshot.data!.docs[index].id;
//               String userName = snapshot.data!.docs[index]['userName'];
//               String password = snapshot.data!.docs[index]['password'];
//               String position = snapshot.data!.docs[index]['position'];
//               bool status = snapshot.data!.docs[index]['status'];

//               return Ink(
//                 decoration: BoxDecoration(
//                   color: firebaseGrey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//                 child: ListTile(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   onTap: () => Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => EditScreen(
//                         currentName: userName,
//                         currentPosition: position,
//                         currentStatus: status,
//                         currentPassword: password,
//                         documentId: docID,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     userName,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     position,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: Text(
//                     status ? 'Status:Running' : 'Status:Trial',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         color: status ? green[900] : red[800],
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               );
//             },
//           );
//         }

//         return Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(
//               firebaseOrange,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
