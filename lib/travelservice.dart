import 'package:cloud_firestore/cloud_firestore.dart';

class TravelService {

  getData() {
    return Firestore.instance.collection('my_tours').snapshots();


}


}