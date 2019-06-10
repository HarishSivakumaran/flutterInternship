import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Hello World"),
        ),
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              AppBar(
                title: Text("Hello World"),
                automaticallyImplyLeading: false,
              ),
              ListTile(
                title: Text("Hello World"),
              )
            ],
          ),
        ),
        body: Center(
          child: Text(
            "Hello World",
            style: TextStyle(fontSize: 34.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
     
    );
  }
}
