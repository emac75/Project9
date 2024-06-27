import 'package:flutter/material.dart';
import 'package:project_9/services/api.dart';
import 'package:project_9/services/account_status.dart';

class LoginPage extends StatefulWidget {
  final String email;
  final String nome;
  final Function() onLogout;

  LoginPage({required this.email, required this.nome, required this.onLogout});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bem-vindo, ${widget.nome}',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountStatus(email: widget.email)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Avançar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  AuthenticationScreen({Key? key}) : super(key: key);

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  String? _loggedInEmail;

  @override
  Widget build(BuildContext context) {
    if (_loggedInEmail != null) {
      return FutureBuilder(
        future: API.fetchUserInfo(_loggedInEmail!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else {
            var responseData = snapshot.data as Map<String, dynamic>;
            var userInfo = responseData['data'] as Map<String, dynamic>;
            return LoginPage(
              email: _loggedInEmail!,
              nome: userInfo['username'] ?? '',
              onLogout: () {
                setState(() {
                  _loggedInEmail = null;
                });
              },
            );
          }
        },
      );
    } else {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(50, 116, 159, 1),
          ),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  AuthenticationTabs(onLogin: (email) {
                    setState(() {
                      _loggedInEmail = email;
                    });
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

class AuthenticationTabs extends StatefulWidget {
  final Function(String) onLogin;

  AuthenticationTabs({Key? key, required this.onLogin}) : super(key: key);

  @override
  AuthenticationTabsState createState() => AuthenticationTabsState();
}

class AuthenticationTabsState extends State<AuthenticationTabs> {
  bool _isLogin = true;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  String? _errorMessage;

  void toggleTab() {
    setState(() {
      _isLogin = !_isLogin;
      if (_isLogin) {
        _nameController.clear();
      } else {
        _emailController.clear();
        _passwordController.clear();
      }
      _errorMessage = null;
    });
  }

  void submitLoginForm() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    try {
      String apiResult = await API.fetchSubmitLoginForm(email, password);
      if (apiResult == 'Login bem-sucedido!') {
        widget.onLogin(email);
        // ignore: use_build_context_synchronously
        Navigator.push(context, MaterialPageRoute(builder: (context) => AccountStatus(email: email)));
      } else {
        setState(() {
          _errorMessage = apiResult;
        });
      }
    } catch (e) {
      print('Erro!');
    }
  }

  void submitRegisterForm() async {
    String username = _nameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    try {
      String apiResult = await API.fetchRegisterForm(username, email, password);
      if (apiResult == 'Utilizador registado com sucesso!') {
        // ignore: use_build_context_synchronously
        Navigator.push(context, MaterialPageRoute(builder: (context) => AccountStatus(email: email)));
      } else {
        setState(() {
          _errorMessage = apiResult;
        });
      }
    } catch (e) {
      print('Erro!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 20),
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/images/profile.jpg'),
            ),
          ),
        ),
        _isLogin
            ? LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                onSubmit: submitLoginForm,
              )
            : RegisterForm(
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                onSubmit: submitRegisterForm,
              ),
        SizedBox(height: 10),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
        SizedBox(height: 10),
        TextButton(
          onPressed: toggleTab,
          child: Text(
            _isLogin ? 'Criar uma conta' : 'Já tem uma conta? Entrar',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Entrar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  RegisterForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Nome',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Registar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
