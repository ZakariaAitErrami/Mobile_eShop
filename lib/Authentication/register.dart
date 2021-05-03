import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shop/Classes/client.dart';
import 'package:e_shop/Widgets/customTextField.dart';
import 'package:e_shop/DialogBox/errorDialog.dart';
import 'package:e_shop/DialogBox/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Store/storehome.dart';
import 'package:e_shop/Config/config.dart';



class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}



class _RegisterState extends State<Register>
{
  final TextEditingController _nameTextEditingController = TextEditingController(); // _means private variable
  final TextEditingController _emailTextEditingController = TextEditingController();
  final TextEditingController _passwordTextEditingController = TextEditingController();
  final TextEditingController _cPasswordTextEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String userImageUrl = "";
  File _imageFile;
  @override
  Widget build(BuildContext context) {
    double _screenWidth = MediaQuery.of(context).size.width, _screenHeight=MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 8.0,),
            InkWell( //. A rectangular area of a Material that responds to touch
              onTap: _selectAndPickImage, //method that  open the gallery
              child: CircleAvatar(
                radius: _screenWidth * 0.15,
                backgroundColor: Colors.white,
                backgroundImage: _imageFile==null ? null : FileImage(_imageFile),
                //if no image is selectd
                child: _imageFile == null ? Icon(Icons.add_photo_alternate, size: _screenWidth*0.15, color: Colors.grey,)
                    : null,
              ),

            ),
            SizedBox(height: 8.0,),
            Form(
              key: _formKey,
              child: Column(
                 children: [
                   CustomTextField( // class in widgets package
                     controller: _nameTextEditingController,
                     data: Icons.person,
                     hintText: "Name",
                     isObsecure: false,
                   ),
                   CustomTextField( // class in widgets package
                     controller: _emailTextEditingController,
                     data: Icons.email,
                     hintText: "Email",
                     isObsecure: false,
                   ),
                   CustomTextField( // class in widgets package
                     controller: _passwordTextEditingController,
                     data: Icons.vpn_key,
                     hintText: "Password",
                     isObsecure: true,
                   ),
                   CustomTextField( // class in widgets package
                     controller: _cPasswordTextEditingController,
                     data: Icons.vpn_key,
                     hintText: "Confirm Password",
                     isObsecure: true,
                   ),
                 ],
              ),
            ),
            RaisedButton(
              onPressed: () => { uploadaAndSaveImage() },
              color: Colors.pink,
              child: Text("Sign up", style: TextStyle(color: Colors.white,)),
            ),
            SizedBox(
              height: 30.0,
            ),
            //adding horizontal line under the button
            Container(
              height: 4.0,
              width: _screenWidth * 0.8,
              color: Colors.pink,
            ),
            SizedBox(
              height: 15.0,
            ),
          ],
        ),
      )
    );
  }
  Future<void> _selectAndPickImage() async{
      //_imageFile = await ImagePicker.pickImage(source: ImageSource.gallery); //send the user to galerry
      final image = await ImagePicker.pickImage(source: ImageSource.gallery);
      setState(() {
        _imageFile = image;
      });
  }

  Future<void> uploadaAndSaveImage() {
    if(_imageFile == null){
      showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(message: "Please select an image",); //class in DialogBox package
        }
      );
    }
    else{
      _passwordTextEditingController.text == _cPasswordTextEditingController.text
          ? _emailTextEditingController.text.isNotEmpty
          && _passwordTextEditingController.text.isNotEmpty
          && _cPasswordTextEditingController.text.isNotEmpty
          && _nameTextEditingController.text.isNotEmpty

          ? uploadToStorage()
          : displayDialog("Please fill up all the fields")
          : displayDialog("Password do not match.");
    }
  }
  displayDialog(String msg){
    showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(message: msg,);
        }
    );
  }
  uploadToStorage() async{
    showDialog(
        context: context,
        builder: (c){
          return LoadingAlertDialog(message : "Registering, Please wait...!"); //class in DialogBox package
        }
    );
    //unique name of the images
    String imageFileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference storageReference = FirebaseStorage.instance.ref().child(imageFileName);
    StorageUploadTask storageUploadTask = storageReference.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;
    await taskSnapshot.ref.getDownloadURL().then((urlImage){
        userImageUrl = urlImage;
        _registerUser();
    });
  }
  FirebaseAuth _auth = FirebaseAuth.instance;
  void _registerUser() async{
    FirebaseUser firebaseUser;
    await _auth.createUserWithEmailAndPassword(email: _emailTextEditingController.text.trim(), password: _passwordTextEditingController.text.trim())
    .then((auth){
        firebaseUser = auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c){
            return ErrorAlertDialog(message: error.message.toString(),);
          }
      );
    });
    if(firebaseUser != null){
      // save user info in firestore
      saveUserInfoToFireStore(firebaseUser).then((value){
        Navigator.pop(context);
        Route route = MaterialPageRoute(builder: (c) => StoreHome());
        Navigator.pushReplacement(context, route);
      });
    }
  }
  Future saveUserInfoToFireStore(FirebaseUser fUser) async{
    final p = client(name: _nameTextEditingController.text.toString().trim(), imUrl: userImageUrl);
    Firestore.instance.collection("users").document(fUser.uid).setData({
      "uid" : fUser.uid,
      "email" : fUser.email,
      "name": p.name,
      "url": p.imUrl,
      EcommerceApp.userCartList : ["garbageValue"],
    });
    await EcommerceApp.sharedPreferences.setString("uid", fUser.uid);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userEmail, fUser.email); //EcommerceApp.userEmail contains the string "email"
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userName, p.name);
    await EcommerceApp.sharedPreferences.setString(EcommerceApp.userAvatarUrl, p.imUrl);
    await EcommerceApp.sharedPreferences.setStringList(EcommerceApp.userCartList, ["garbageValue"]); //list because cart can contain multiple items garbagevalue is the value affected to the cart before buying
  }
}

