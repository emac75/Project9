// ignore_for_file: prefer_const_constructors, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:project_9/services/api.dart';

class MyHeaderDrawer extends StatefulWidget {
  final String email;
  const MyHeaderDrawer({required this.email});

  @override
  State<MyHeaderDrawer> createState() => _MyHeaderDrawerState();
}

class _MyHeaderDrawerState extends State<MyHeaderDrawer> {
  String _username = '';
  void initState() {
    super.initState();
    getUserData(widget.email);
  }

  Widget build(BuildContext context) {
    return Container(
      color: Color.fromRGBO(50, 116, 159, 1),
      width: double.infinity,
      height: 200,
      padding: EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10),
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/profile.jpg'),
              ),
            ),
          ),
          //Nome do utilizador
          Text(_username, style: TextStyle(color: Colors.white, fontSize: 20),),
          //Email do utilizador
          Text(widget.email, style: TextStyle(color: Colors.grey, fontSize: 14,),),
        ],
      ),
    );
  }

  void getUserData(String email) async {
    try {
      Map<String, dynamic> apiResult = await API.fetchUserDetail(email);
      setState(() {
        _username = apiResult['data']['username'];
     });  
    } catch (e) {
      print('Erro: $e');
    }
  }
}

