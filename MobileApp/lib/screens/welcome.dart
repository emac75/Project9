import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remover seta de voltar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Validou com sucesso o acesso à aplicação",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Bem-vindo à aplicação Anti DeepFakes. Pode aceder ao menu para verificar as opções disponíveis.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Efetue Operações Sensíveis com Segurança",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "A nossa aplicação oferece um ambiente seguro para realizar operações sensíveis, incluindo transações financeiras. Utilizando tecnologia avançada de autenticação biométrica, garantimos que apenas você tem acesso às suas informações pessoais e financeiras. Esteja tranquilo ao efetuar pagamentos, transferências e outras operações críticas, sabendo que os seus dados estão protegidos contra fraudes e acessos não autorizados. A segurança é a nossa prioridade, permitindo-lhe focar-se no que realmente importa.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
