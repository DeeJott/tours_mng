import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {


  const MapPage({
    Key key,
    @required this.documents,
    @required this.initialPosition,
    @required this.mapController,
  }) : super(key: key);

  final LatLng initialPosition;
  final DocumentSnapshot documents;
  final GoogleMapController mapController;

  @override
  _MapPageState createState() => _MapPageState();

}

class _MapPageState extends State<MapPage> {




  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(-33.870839, 151.206407),
            zoom: 12,
          ),
          mapType: MapType.normal,
          markers: documents
              .map((document) => Marker(
              markerId: MarkerId(document['spot_id']),
              icon: BitmapDescriptor.defaultMarker,
              position: LatLng(
                document['location'].latitude,
                document['location'].longitude,
              ),
              infoWindow: InfoWindow(
                title: document['name'],
                snippet: document['type'],
              )))
              .toSet(),
          onMapCreated: (mapController) {
            this.mapController.complete(mapController);
          },
        ),
      ],
    );
  }
}
