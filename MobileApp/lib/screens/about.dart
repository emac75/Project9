import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre a Aplicação', style: TextStyle(color: Colors.black)),
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
                "Designação do Projeto",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Sistema de Autenticação digital anti Deepfakes baseado em Reconhecimento facial e Biometria de voz.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Descrição e objetivos",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Com o avanço da tecnologia, novos métodos para falsificar a identidade de pessoas, como os Deepfakes, emergem. O emprego de sistemas que integram o Reconhecimento Facial e Biometria de Voz surgem como uma solução promissora na luta contra essas fraudes, proporcionando uma autenticação e identificação mais robustas e confiáveis. Estes tipos de sistemas possibilitam autenticação em diversas áreas de aplicação, incluindo o acesso a dispositivos e aplicativos, transações financeiras, controle de acesso físico, e outras funcionalidades. O objetivo desta proposta é implementar um aplicativo para dispositivos móveis de autenticação que integre o Reconhecimento facial e Biometria de voz. A proposta visa garantir a segurança e fiabilidade na autenticação de pessoas e facilidade de uso para proporcionar uma experiência simples e intuitiva ao utilizador.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Desenvolvido pelos candidatos",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "19970423 - Edgar Casimiro\n30008210 - Miguel Fernandes\n30008361 - Pedro Brito\n30010863 - Tiago Mateus",
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
