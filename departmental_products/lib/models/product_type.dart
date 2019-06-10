import 'package:flutter/material.dart';

class Product {
  String title;
  String description;
  double price;
  String id;
  String imageURL;
  bool isFavourite;
  String userID;
  String email;
  Product({
    @required this.id,
    @required this.description,
    @required this.imageURL,
    @required this.price,
    @required this.title,
    this.isFavourite = false,
    @required this.email,
    @required this.userID,
  });
}
