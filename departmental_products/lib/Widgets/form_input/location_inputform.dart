import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "package:map_view/map_view.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationFormField extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LocationFormFieldState();
  }
}

class _LocationFormFieldState extends State<LocationFormField> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  Uri staticUri;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(updateAddress);
  }

@override
  void dispose() {
    super.dispose();
    textEditingController.removeListener(updateAddress);
  }

  void getStaticUri(String address) {
    if (address.isEmpty) {
      return;
    }


    final Uri uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json',
        {"address": address, "key": "AIzaSyDvquu68nN4ZWSELhAkMvj3VvFk-maR8zk"});

    http.get(uri).then((http.Response response) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData);
      final formattedAddress = responseData["results"][0]["formatted_address"];
      final coords = responseData["results"][0]["geometry"]["location"];
      textEditingController.text = formattedAddress.toString();
      StaticMapProvider staticMapProvider =
          StaticMapProvider("AIzaSyDvquu68nN4ZWSELhAkMvj3VvFk-maR8zk");
      staticUri = staticMapProvider.getStaticUriWithMarkers(
        [Marker("position", "positon", coords["lat"], coords["lng"])],
        center: Location(
          coords["lat"],
          coords["lng"],
        ),
        height: 300,
        width: 500,
        maptype: StaticMapViewType.roadmap,
      );
      setState(() {
        textEditingController.text = formattedAddress;
      });
    });
  }

  void updateAddress() {
    if (!focusNode.hasFocus) {
      getStaticUri(textEditingController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: focusNode,
          controller: textEditingController,
          decoration: InputDecoration(labelText: "Address"),
        ),
        SizedBox(
          height: 2.0,
        ),
        Image.network(staticUri.toString()),
      ],
    );
  }
}
