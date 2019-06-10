import 'dart:math';
import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';
import '../models/product_type.dart';
import '../models/user_type.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:rxdart/subjects.dart';

mixin ConnectedProUserScopedModel on Model {
  List<Product> _productsList = new List<Product>();

  String _selectedProducID;

  User _authenticatedUser;

  Product _selectedProduct;

  bool _isLoading = false;

  User get authenticatedUser {
    return _authenticatedUser;
  }

  Future<bool> addProduct(String title, String description, double price,
      String userID, String email, String imageURL) {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic> productFireBase = {
      "title": title,
      "description": description,
      "price": price,
      "imageURL":
          "https://images.pexels.com/photos/356365/pexels-photo-356365.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
      "userID": _authenticatedUser.id,
      "email": _authenticatedUser.email,
    };

    return http
        .post(
      "https://flutterproducts-5ca6d.firebaseio.com/products.json?auth=${_authenticatedUser.token}",
      body: json.encode(productFireBase),
    )
        .then((http.Response response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        Product product = Product(
          title: title,
          description: description,
          imageURL: imageURL,
          userID: userID,
          email: email,
          price: price,
          id: responseData["name"],
        );
        _productsList.add(product);
        _selectedProducID = null;

        _isLoading = false;

        notifyListeners();
        return true;
      }
      _isLoading = false;

      notifyListeners();
      return false;
    }).catchError((onError) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }
}
mixin UserScopedModel on ConnectedProUserScopedModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject<bool>();

  Future<Map<String, dynamic>> login({String email, String password}) {
    _isLoading = true;
    notifyListeners();
    Map<String, dynamic> authData = {
      "email": email,
      "password": password,
      "returnSecureToken": true
    };
    return http.post(
      "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyCl9YSPmfWbNOyOm2kiW950DX2voIrAGtc",
      body: json.encode(authData),
      headers: {"Content-Type": "application/json"},
    ).then((http.Response response) {
      Map<String, dynamic> responseData = json.decode(response.body);
      bool hasError = true;
      String message = "Email not found!";
      if (responseData.containsKey("idToken")) {
        hasError = false;

        message = "Authentication succeeded";
        _authenticatedUser = User(
            email: email,
            id: responseData["localId"],
            token: responseData["idToken"]);
        SharedPreferences.getInstance()
            .then(((SharedPreferences sharedPreferences) {
          sharedPreferences.setString("token", responseData["idToken"]);
          sharedPreferences.setString("email", email);
          sharedPreferences.setString("id", responseData["localId"]);
          setAuthTimeout(int.parse(responseData["expiresIn"]));
          DateTime now = DateTime.now();
          DateTime expireTime =
              now.add(Duration(seconds: int.parse(responseData["expiresIn"])));
          sharedPreferences.setString(
              "expiryTime", expireTime.toIso8601String());
          _userSubject.add(true);
        }));
      } else if (responseData["error"]["errors"][0]["message"] ==
          "EMAIL_NOT_FOUND") {
      } else if (responseData["error"]["errors"][0]["message"] ==
          "INVALID_PASSWORD") {
        message = "Password is invalid!";
      } else if (responseData["error"]["errors"][0]["message"] ==
          "USER_DISABLED") {
        message = "Admin has disabled you!";
      }
      _isLoading = false;
      notifyListeners();
      return {"success": !hasError, "message": message};
    });
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }

  //  _authenticatedUser =
  //       User(id: "lcalcdsklc", email: email, password: password);
  void authAutomatic() {
    SharedPreferences.getInstance().then((SharedPreferences sharedPreferences) {
      String token = sharedPreferences.getString("token");
      String expiryTimeString = sharedPreferences.getString("expiryTime");
      DateTime expiryTime = DateTime.parse(expiryTimeString);
      if (token != null && expiryTime.isAfter(DateTime.now())) {
        setAuthTimeout(expiryTime.difference(DateTime.now()).inSeconds);
        String email = sharedPreferences.getString("email");
        _userSubject.add(true);

        String id = sharedPreferences.getString("id");
        _authenticatedUser = User(email: email, id: id, token: token);
        notifyListeners();
      } else {
        _authenticatedUser = null;
        notifyListeners();
      }
    });
  }

  User get authUser {
    return _authenticatedUser;
  }

  Future<Map<String, dynamic>> signup(String email, String password) {
    _isLoading = true;
    notifyListeners();
    Map<String, dynamic> authData = {
      "email": email,
      "password": password,
      "returnSecureToken": true
    };

    return http.post(
        "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyCl9YSPmfWbNOyOm2kiW950DX2voIrAGtc",
        body: json.encode(authData),
        headers: {
          "Content-Type": "application/json"
        }).then((http.Response response) {
      Map<String, dynamic> responseData = json.decode(response.body);
      bool hasError = true;
      String message = "User already exists!";
      if (responseData.containsKey("idToken")) {
        hasError = false;
        message = "Authentication succeeded";
        _authenticatedUser = User(
            email: email,
            id: responseData["localId"],
            token: responseData["idToken"]);
        SharedPreferences.getInstance()
            .then(((SharedPreferences sharedPreferences) {
          sharedPreferences.setString("token", responseData["idToken"]);
          sharedPreferences.setString("email", email);
          sharedPreferences.setString("id", responseData["localId"]);
          String expiryTimeString = sharedPreferences.getString("expiryTime");
          DateTime expiryTime = DateTime.parse(expiryTimeString);
          setAuthTimeout(expiryTime.difference(DateTime.now()).inSeconds);
          _userSubject.add(true);
        }));
      } else if (responseData["error"]["errors"][0]["message"] ==
          "EMAIL_EXISTS") {
      } else {
        message = "Something went wrong!!";
      }
      _isLoading = false;
      notifyListeners();
      return {"success": !hasError, "message": message};
    });
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  void logout() {
    _authenticatedUser = null;
    SharedPreferences.getInstance().then((SharedPreferences sharedPrefs) {
      // sharedPrefs.clear();
      print("logout");
      _authTimer = null;
      sharedPrefs.remove("token");
      sharedPrefs.remove("email");
      sharedPrefs.remove("id");
      _userSubject.add(false);
      notifyListeners();
    });
  }
}

mixin ProductsScopedModel on ConnectedProUserScopedModel {
  bool _shouldDisplayFavourite = false;

  bool get shouldDisplayFavourites {
    return _shouldDisplayFavourite;
  }

  List<Product> get products {
    return List.from(_productsList);
  }

  List<Product> get diplayFilteredProducts {
    if (_shouldDisplayFavourite) {
      return List.from(
          _productsList.where((Product e) => e.isFavourite).toList());
    }
    return List.from(_productsList);
  }

  Future<bool> deleteProduct() {
    final String productID = _selectedProduct.id;
    _productsList.remove(_selectedProduct);
    _selectedProducID = null;
    _isLoading = true;
    notifyListeners();

    return http
        .delete(
      "https://flutterproducts-5ca6d.firebaseio.com/products/$productID.json?auth=${_authenticatedUser.token}",
    )
        .then((_) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((onError) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<bool> fetchData() {
    _isLoading = true;
    notifyListeners();

    return http
        .get(
            "https://flutterproducts-5ca6d.firebaseio.com/products.json?auth=${_authenticatedUser.token}")
        .then((http.Response response) {
      final List<Product> fetchedListProducts = [];
      final Map<String, dynamic> productListData = json.decode(response.body);

      if (productListData == null) {
        _isLoading = false;

        notifyListeners();
        return true;
      }

      productListData.forEach((String productID, dynamic iProduct) {
        Product product = new Product(
            id: productID,
            description: iProduct["description"],
            imageURL: iProduct["imageURL"],
            price: iProduct["price"],
            title: iProduct["title"],
            userID: iProduct["userID"],
            email: iProduct["email"],
            isFavourite: iProduct["wishlist"] == null
                ? false
                : (iProduct["wishlist"] as Map<String, dynamic>)
                    .containsKey(_authenticatedUser.id));
        fetchedListProducts.add(product);
      });

      _productsList = fetchedListProducts.where((Product product) {
        return product.userID == _authenticatedUser.id;
      }).toList();
      _isLoading = false;

      notifyListeners();
      return true;
    }).catchError((onError) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Product get selectedProduct {
    return _selectedProduct;
  }

  void toggleFavouriteProduct(int index) {
    Product updatedProduct = Product(
      id: _selectedProduct.id,
      title: _selectedProduct.title,
      imageURL: _selectedProduct.imageURL,
      description: _selectedProduct.description,
      price: _selectedProduct.price,
      userID: _selectedProduct.id,
      email: _selectedProduct.email,
      isFavourite: _selectedProduct.isFavourite ? false : true,
    );
    _productsList[index] = updatedProduct;
    _selectedProducID = null;
    notifyListeners();
    if (updatedProduct.isFavourite) {
      http
          .put(
              "https://flutterproducts-5ca6d.firebaseio.com/products/${_selectedProduct.id}/wishlist/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}",
              body: json.encode(true))
          .then((http.Response response) {
        if (response.statusCode != 200 && response.statusCode != 201) {
          Product updatedProducte = Product(
            id: _selectedProduct.id,
            title: _selectedProduct.title,
            imageURL: _selectedProduct.imageURL,
            description: _selectedProduct.description,
            price: _selectedProduct.price,
            userID: _selectedProduct.id,
            email: _selectedProduct.email,
            isFavourite: !updatedProduct.isFavourite,
          );
          _productsList[index] = updatedProducte;
          _selectedProducID = null;
          notifyListeners();
        }
      }).catchError((onError) {
        Product updatedProducte = Product(
          id: _selectedProduct.id,
          title: _selectedProduct.title,
          imageURL: _selectedProduct.imageURL,
          description: _selectedProduct.description,
          price: _selectedProduct.price,
          userID: _selectedProduct.id,
          email: _selectedProduct.email,
          isFavourite: !updatedProduct.isFavourite,
        );
        _productsList[index] = updatedProducte;
        _selectedProducID = null;
        notifyListeners();
      });
    } else {
      http
          .delete(
        "https://flutterproducts-5ca6d.firebaseio.com/products/${_selectedProduct.id}/wishlist/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}",
      )
          .then((http.Response response) {
        if (response.statusCode != 200 && response.statusCode != 201) {
          Product updatedProducte = Product(
            id: _selectedProduct.id,
            title: _selectedProduct.title,
            imageURL: _selectedProduct.imageURL,
            description: _selectedProduct.description,
            price: _selectedProduct.price,
            userID: _selectedProduct.id,
            email: _selectedProduct.email,
            isFavourite: !updatedProduct.isFavourite,
          );
          _productsList[index] = updatedProducte;
          _selectedProducID = null;
          notifyListeners();
        }
      }).catchError((onError) {
        Product updatedProducte = Product(
          id: _selectedProduct.id,
          title: _selectedProduct.title,
          imageURL: _selectedProduct.imageURL,
          description: _selectedProduct.description,
          price: _selectedProduct.price,
          userID: _selectedProduct.id,
          email: _selectedProduct.email,
          isFavourite: !updatedProduct.isFavourite,
        );
        _productsList[index] = updatedProducte;
        _selectedProducID = null;
        notifyListeners();
      });
    }
  }

  Future<bool> updateProduct(String title, String description, double price,
      String userID, String email, String imageURL) {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic> updatedProduct = {
      "title": title,
      "description": description,
      "imageURL": imageURL,
      "userID": _selectedProduct.userID,
      "email": _selectedProduct.email,
      "price": price,
      "id": _selectedProduct.id,
    };
    return http
        .put(
            "https://flutterproducts-5ca6d.firebaseio.com/products/${updatedProduct["id"]}.json?auth=${_authenticatedUser.token}",
            body: json.encode(updatedProduct))
        .then((http.Response response) {
      Product product = Product(
        title: title,
        description: description,
        imageURL: imageURL,
        userID: _selectedProduct.userID,
        email: _selectedProduct.email,
        price: price,
        id: _selectedProduct.id,
      );

      _selectedProduct = product;
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((onError) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  String get selectedProductID {
    return _selectedProducID;
  }

  set selectedProductID(String productID) {
    _selectedProducID = productID;

    if (productID != null) {
      _selectedProduct = _productsList.firstWhere((Product product) {
        return product.id == productID;
      });
      notifyListeners();
    }
  }

  void callNotifyListeners() {
    _selectedProducID = null;
    notifyListeners();
  }

  void toggleFavDisplay() {
    _shouldDisplayFavourite = !_shouldDisplayFavourite;
    notifyListeners();
  }
}

mixin UtilityScopedModel on ConnectedProUserScopedModel {
  bool get isLoading {
    return _isLoading;
  }
}
