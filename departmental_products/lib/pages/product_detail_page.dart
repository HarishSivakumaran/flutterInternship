import 'package:flutter/material.dart';
import 'package:navigation_practice/scoped_models/main_scoped.dart';
import 'dart:async';
import 'package:scoped_model/scoped_model.dart';

import 'package:navigation_practice/Widgets/ui_elements/title_default.dart';
import '../models/product_type.dart';

class ProductsDetailpage extends StatelessWidget {
  final String productID;

  ProductsDetailpage(this.productID);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ScopedModelDescendant<MainScopedModel>(
        builder: (BuildContext context, Widget child, MainScopedModel model) {
          Product selProduct = model.products.firstWhere((Product product) {
            return product.id == productID;
          });

          return WillPopScope(
            onWillPop: () {
              model.selectedProductID = null;
              return Future.value(true);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(selProduct.title),
              ),
              body: Column(
                children: <Widget>[
                  FadeInImage(
                    image: NetworkImage(selProduct.imageURL),
                    height: 350,
                    fit: BoxFit.cover,
                    placeholder: AssetImage("assets/auth_bg.jpeg"),
                  ),
                  // Container(
                  //   margin: EdgeInsets.all(10.0),
                  //   child: RaisedButton(
                  //     onPressed: () {
                  //       showDialog(
                  //           context: context,
                  //           builder: (BuildContext context) {
                  //             return AlertDialog(
                  //               title: Text("Are you sure?"),
                  //               content: Text("It can't be undone!"),
                  //               actions: <Widget>[
                  //                 FlatButton(
                  //                   onPressed: () {
                  //                     Navigator.pop(context);
                  //                   },
                  //                   child: Text("Discard",style: TextStyle(fontSize: 20.0),),
                  //                 ),
                  //                 FlatButton(
                  //                   onPressed: () {
                  //                     Navigator.pop(context);
                  //                     Navigator.pop(context, true);
                  //                   },
                  //                   child: Text("Continue",style: TextStyle(fontSize: 20.0),),
                  //                 )
                  //               ],
                  //             );
                  //           });
                  //     },
                  //     child: Text("Delete Product"),
                  //   ),
                  // ),
                  TitleDefault(selProduct.title),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Pondicherry,India",
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Oswald",
                          )),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text("|",
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Oswald",
                            )),
                      ),
                      Text("\$" + selProduct.price.toString(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Oswald",
                          )),
                    ],
                  ),
                  Container(
                    child: Text(
                      selProduct.description,
                      textAlign: TextAlign.center,
                    ),
                    padding: EdgeInsets.all(10.0),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
