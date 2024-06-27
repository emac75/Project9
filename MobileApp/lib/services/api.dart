import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_9/utils/constants.dart';

//Ligar a API

class API {
  static Future<Map<String, dynamic>> fetchUserInfo(String email) async {
    var url = Uri.parse('$API_ADDRESS/userinfo');

    var corpo = json.encode({
      'email': email,
    });

    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      return json.decode(resposta.body);
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchUserDetail(String email) async {
    var url = Uri.parse('$API_ADDRESS/userinfo');

    var corpo = json.encode({
      'email': email,
    });

    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      return json.decode(resposta.body);
    } catch (e) {
      return {};
    }
  }

  static Future<String> fetchSubmitLoginForm(String email, String password) async {
    var url = Uri.parse('$API_ADDRESS/login');
    var corpo = json.encode({
      'email': email,
      'password': password,
    });
    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      final responseData = json.decode(resposta.body);
      if (resposta.statusCode == 200) {
        return(responseData['message']);
      } else {
        return(responseData['message']);
      }
    } catch (e) {
      return('Ups.. Algo deu errado, verifique os dados e tente novamente');
    }
  }

  static Future<String> fetchRegisterForm(String username, String email, String password) async {
    var url = Uri.parse('$API_ADDRESS/register');
    var corpo = json.encode({
      'username': username,
      'email': email,
      'password': password,
    });
    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      final responseData = json.decode(resposta.body);
      if (resposta.statusCode == 200) {
        return(resposta.body);
      } else {
        return(responseData['message']);
      }
    } catch (e) {
        return('Ups.. Algo deu errado, verifique os dados e tente novamente');
    }
  }

  static Future<Object> fetchUserBio(String email) async {
    bool registo = false;
    var url = Uri.parse('$API_ADDRESS/userinfo');
    var corpo = json.encode({
      'email': email,
    });
    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      if (resposta.statusCode == 200) {
        var userInfo = await API.fetchUserInfo(email);
        if (userInfo['data'].containsKey('cameradata')) {
          registo = true;
        }
      }
      return registo;
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchPhrase() async {
    var url = Uri.parse('$API_ADDRESS/phrase');
    var corpo = json.encode({});
    try {
      var resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpo,
      );
      return json.decode(resposta.body);
    } catch (e) {
      return {};
    }
  }
}