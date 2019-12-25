import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'travelservice.dart';
import 'tours.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MnG Map',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MainPage(),
    );
  }
}

// ignore: must_be_immutable
class TourPage extends StatefulWidget {
  TourPage({Key key, this.title, this.documents}) : super(key: key);

  final String title;
  final List<DocumentSnapshot> documents;

  @override
  _TourPageState createState() => _TourPageState();
}

class _TourPageState extends State<TourPage> {
  // ignore: non_constant_identifier_names
  Stream<QuerySnapshot> my_tours;
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();
    my_tours = Firestore.instance.collection('my_tours').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new StreamBuilder(
        stream: Firestore.instance
            .collection('my_tours')
            .document('sydney_downtown_guide')
            .collection('places')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          return Column(
            children: <Widget>[
              Flexible(
                flex: 2,
                child: TourMap(
                  documents: snapshot.data.documents,
                  mapController: _mapController,
                  initialPosition: LatLng(-33.870663, 151.206793),
                ),
              ),
              Flexible(
                flex: 3,
                child: TourList(
                    documents: snapshot.data.documents,
                    mapController: _mapController),
              )
            ],
          );
        },
      ),
    );
  }
}

class TourList extends StatelessWidget {
  const TourList(
      {Key key, @required this.documents, @required this.mapController})
      : super(key: key);

  final List<DocumentSnapshot> documents;
  final Completer<GoogleMapController> mapController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (builder, index) {
        final document = documents[index];
        return ListTile(
          title: Text(document['name']),
          onTap: () async {
            final controller = await mapController.future;
            await controller
                .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              target: LatLng(
                document['location'].latitude,
                document['location'].longitude,
              ),
              zoom: 15,
            )));
          },
        );
      },
    );
  }
}

class TourMap extends StatelessWidget {
  const TourMap({
    Key key,
    @required this.documents,
    @required this.initialPosition,
    @required this.mapController,
  }) : super(key: key);

  final LatLng initialPosition;
  final List<DocumentSnapshot> documents;
  final Completer<GoogleMapController> mapController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
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

// ListView example

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TabController tabController;

  var tripDetails;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 3, vsync: this);

    setState(() {
      tripDetails = TravelService().getData();
    });
  }

  getTravelEntries() {
    if (tripDetails != null) {
      return StreamBuilder(
          stream: tripDetails,
          // ignore: missing_return
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return ListView.builder(
                primary: false,
                shrinkWrap: true,
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, i) {
                  return new Column(
                    children: <Widget>[
                      _buildImageGrid(
                          snapshot.data.documents[i].data['images']),
                      _imgGalleryDetail(
                        snapshot.data.documents[i].data['tourname'],
                        snapshot.data.documents[i].data['region'],
                      )
                    ],
                  );
                },
              );
            }
          });
    } else {
      return new Text('Loading... Please Wait');
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: <Widget>[getTravelEntries()],
      ),
    );
  }

  Widget _imgGalleryDetail(name, region) {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 15.0),
      child: Column(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    fontSize: 15.0),
              ),
              SizedBox(height: 7.0),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                region,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    fontSize: 12.0),
              ),
              SizedBox(height: 7.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(images) {
    return GestureDetector(
      child: Padding(
          padding: EdgeInsets.only(top: 25.0, left: 15.0, right: 15.0),
          child: Container(
            height: 225.0,
            child: Row(
              children: <Widget>[
                Container(
                  height: 225.0,
                  width: MediaQuery.of(context).size.width / 2 + 40.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          bottomLeft: Radius.circular(15.0)),
                      image: DecorationImage(
                          image: NetworkImage(images[0]), fit: BoxFit.cover)),
                ),
                SizedBox(width: 2.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 111.5,
                      width: MediaQuery.of(context).size.width / 2 - 72.0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15.0),
                          ),
                          image: DecorationImage(
                              image: NetworkImage(images[1]),
                              fit: BoxFit.cover)),
                    ),
                    SizedBox(height: 2.0),
                    Container(
                      height: 111.5,
                      width: MediaQuery.of(context).size.width / 2 - 72.0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(15.0)),
                          image: DecorationImage(
                              image: NetworkImage(images[2]),
                              fit: BoxFit.cover)),
                    ),
                  ],
                )
              ],
            ),
          )),
      onTap: () {},
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  StreamSubscription<QuerySnapshot> subscription;

  List<DocumentSnapshot> documents;


  CollectionReference collectionReference =
      Firestore.instance.collection('my_tours');

  @override
  void initState() {
    subscription = collectionReference.snapshots().listen((datasnapshot) {
      setState(() {
        documents = datasnapshot.documents;

      });
    });
    super.initState();
  }

  passData(DocumentSnapshot snap, LatLng coords, GoogleMapController controll) {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => MapPage(
              documents: snap,
              initialPosition: coords,
              mapController: controll,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        new Container(
          height: MediaQuery.of(context).size.height,
          child: new ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return InkWell(
                  child: Card(
                    elevation: 10,
                    child: Container(
                      margin: EdgeInsets.all(10.0),
                      child: new Column(
                        children: <Widget>[
                          new ClipRRect(
                            borderRadius: new BorderRadius.circular(10.0),
                            child: new Image.network(
                              documents[index].data['image'],
                              height: 180.0,
                              width: 180.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                          new SizedBox(
                            height: 10.0,
                          ),
                          new Text(documents[index].data['tourname'])
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    passData(documents[index],);
                  },
                );
              }),
        )
      ],
    );
  }
}
