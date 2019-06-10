import 'dart:io';

import 'package:flutter/material.dart';
import 'package:navigation_practice/Widgets/form_input/location_inputform.dart';
import 'package:navigation_practice/scoped_models/main_scoped.dart';
import '../models/product_type.dart';
import 'package:scoped_model/scoped_model.dart';

class CreateAndEditProductPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CreateAndEditProductPageState();
  }
}

class _CreateAndEditProductPageState extends State<CreateAndEditProductPage> {
  final Product _formData = Product(
      imageURL:
          "https://images.pexels.com/photos/356365/pexels-photo-356365.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
      title: "",
      description: "",
      price: null);
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  Widget _buildTitleTextFormField(MainScopedModel model) {
    return (TextFormField(
      validator: (String value) {
        if ((value.trim().isEmpty) || (value.length < 5)) {
          return "Title is required and should be atleast 5 characters";
        }
      },
      initialValue:
          model.selectedProductID != null ? model.selectedProduct.title : "",
      onSaved: (String value) {
        _formData.title = value;
      },
      decoration: InputDecoration(labelText: "Product Title"),
      keyboardType: TextInputType.text,
    ));
  }

  Widget _buildDescriptionTextFormField(MainScopedModel model) {
    return (TextFormField(
      onSaved: (String value) {
        _formData.description = value;
      },
      validator: (String value) {
        if ((value.trim().isEmpty) || (value.length < 5)) {
          return "Description is required and should be atleast 5 characters";
        }
      },
      initialValue: model.selectedProductID != null
          ? model.selectedProduct.description
          : "",
      decoration: InputDecoration(
        labelText: "Product Description",
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 4,
    ));
  }

  Widget _buildPriceTextFormField(MainScopedModel model) {
    return (TextFormField(
      onSaved: (String value) {
        _formData.price = double.parse(value.replaceFirst(",", "."));
      },
      initialValue: model.selectedProductID != null
          ? model.selectedProduct.price.toString()
          : "",
      validator: (String value) {
        if ((value.trim().isEmpty) ||
            !(RegExp(r"^([0-9]+\.?[0-9]*)$")
                .hasMatch(value.replaceFirst(",", ".")))) {
          return "Price is required and should be a number";
        }
      },
      decoration: InputDecoration(labelText: "Product Price"),
      keyboardType: TextInputType.number,
    ));
  }

  Widget _buildButtonOrProgressBar() {
    return ScopedModelDescendant<MainScopedModel>(
      builder: (BuildContext context, Widget child, MainScopedModel model) {
        if (model.isLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return RaisedButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                if (model.selectedProductID == null) {
                  _formData.userID = model.authenticatedUser.id;
                  _formData.email = model.authenticatedUser.email;
                  model
                      .addProduct(
                    _formData.title,
                    _formData.description,
                    _formData.price,
                    _formData.userID,
                    _formData.email,
                    _formData.imageURL,
                  )
                      .then((bool success) {
                    if (success) {
                      Navigator.pushReplacementNamed(context, '/').then((_) {
                        model.selectedProductID = null;
                      });
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Something went wrong"),
                              content: Text(
                                  "Please check your network connectivity"),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text("Okay"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            );
                          });
                    }
                  });
                } else {
                  _formData.isFavourite = model.selectedProduct.isFavourite;
                  _formData.email = model.authenticatedUser.email;
                  _formData.userID = model.authenticatedUser.id;
                  model
                      .updateProduct(
                    _formData.title,
                    _formData.description,
                    _formData.price,
                    _formData.userID,
                    _formData.email,
                    _formData.imageURL,
                  )
                      .then((bool success) {
                    if (success) {
                      Navigator.pushReplacementNamed(context, "/");
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Something went wrong!"),
                              content: Text(
                                  "Please check your network connectivity"),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text("Okay"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            );
                          });
                    }
                  });
                }
              }
            },
            child: Text(
              "Save",
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            color: Theme.of(context).accentColor,
          );
        }
      },
    );
  }

//########################################BUILD###########################################
  @override
  Widget build(BuildContext context) {
    final double devWidth = MediaQuery.of(context).size.width;
    final double targetWidth =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? devWidth * 0.9
            : devWidth * 0.7;
    final double targetPadding = devWidth - targetWidth;
    final Widget pageContent = ScopedModelDescendant<MainScopedModel>(
      builder: (BuildContext context, Widget child, MainScopedModel model) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: targetPadding / 3, vertical: 10.0),
              children: <Widget>[
                _buildTitleTextFormField(model),
                _buildDescriptionTextFormField(model),
                _buildPriceTextFormField(model),
                LocationFormField(),
                Container(
                  margin: EdgeInsets.all(10.0),
                  child: _buildButtonOrProgressBar(),
                )
              ],
            ),
          ),
        );
      },
    );

    return ScopedModelDescendant<MainScopedModel>(
      builder: (BuildContext context, Widget child, MainScopedModel model) {
        return model.selectedProductID != null
            ? Scaffold(
                appBar: AppBar(
                  title: Text("Edit Text"),
                ),
                body: pageContent,
              )
            : pageContent;
      },
    );
  }
}
