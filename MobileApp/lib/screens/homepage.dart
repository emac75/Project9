import 'package:flutter/material.dart';
import 'package:project_9/screens/about.dart';
import 'package:project_9/screens/deletebio.dart';
import 'package:project_9/screens/welcome.dart';
import 'package:project_9/my_drawer_header.dart';
import 'package:project_9/screens/splash.dart';

class HomePage extends StatefulWidget {
  final String email;
  
  const HomePage({required this.email});
  
  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var currentPage = DrawerSections.welcome;

  @override
  Widget build(BuildContext context) {
    var container;
    if (currentPage == DrawerSections.welcome) {
      container = WelcomePage();
    }
    else if (currentPage == DrawerSections.deletebio) {
      container = DeletebioPage(email: widget.email);
    }
    else if (currentPage == DrawerSections.about) {
      container = AboutPage();
    }
    else if (currentPage == DrawerSections.splash) {
      container = SplashScreen();
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(50, 116, 159, 1),
        title: Text("Project 9"),
        ),
        body: container,
        drawer: Drawer(
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  MyHeaderDrawer(email: widget.email),
                  MyDrawerList(),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget MyDrawerList(){
    return Container(
      padding: EdgeInsets.only(top: 15,),
      child: Column(
        //Lista do menu
        children: [
          menuItem(1, "Homepage", Icons.home_outlined, currentPage == DrawerSections.welcome ? true:false),
          //menuItem(2, "Em Construção", Icons.construction_outlined, currentPage == DrawerSections.dashboard ? true:false),
          menuItem(2, "Biometria", Icons.delete_outline_rounded, currentPage == DrawerSections.deletebio ? true:false),
          const Divider(),
          menuItem(3, "Sobre", Icons.people_alt_outlined, currentPage == DrawerSections.about ? true:false),
          const Divider(),
          menuItem(4, "Terminar Sessão", Icons.exit_to_app_rounded, currentPage == DrawerSections.splash ? true:false),
        ],
      ),
    );
  }

  Widget menuItem(int id, String title, IconData icon, bool selected){
    return Material(
      color: selected ? Colors.grey[300] : Colors.transparent,
      child: InkWell(
        onTap: (){
          Navigator.pop(context);
          setState(() {
            if (id == 1) {
              currentPage = DrawerSections.welcome;
            } else if (id == 2) {
              currentPage = DrawerSections.deletebio;
            } else if (id == 3) {
              currentPage = DrawerSections.about;
            } else if (id == 4) {
              currentPage = DrawerSections.splash;
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(child: Icon(icon, size:20, color:Colors.black)
              ),
              Expanded(flex:1, child: Text(title, style:TextStyle(color:Colors.black, fontSize: 16))
              ),
            ],
          ),
        ),
      ),  
    );
  }
}

enum DrawerSections {
  welcome,
  deletebio,
  about,
  splash,
}