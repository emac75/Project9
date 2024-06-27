import 'package:flutter/material.dart';
import 'package:project_9/bio/bio_reg_welcome.dart';
import 'package:project_9/bio/bio_reg_login.dart';
import 'package:project_9/services/api.dart';

class AccountStatus extends StatefulWidget {
  final String email;
  const AccountStatus({required this.email});

  @override
  _AccountStatusState createState() => _AccountStatusState();
}

class _AccountStatusState extends State<AccountStatus> {
  late Future<bool> _userBioFuture;

  @override
  void initState() {
    super.initState();
    _userBioFuture = checkUserBio(widget.email);
  }

  Future<bool> checkUserBio(String email) async {
    try {
      Object userBio = await API.fetchUserBio(email);
      if (userBio == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _userBioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro ao verificar estado da conta'));
        } else if (snapshot.hasData) {
          bool registo = snapshot.data ?? false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (registo) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BioLoginCreatePage(email: widget.email)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BioRegWelcomePage(email: widget.email)),
              );
            }
          });
          return Container(); // Retorna um container vazio enquanto espera o redirecionamento
        } else {
          return Center(child: Text('Erro inesperado'));
        }
      },
    );
  }
}
