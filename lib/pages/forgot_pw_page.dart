import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/components/my_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message.toString()),
            );
          });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[200],
        elevation: 0,
      ),
      body: Column(
          children: [
            Text('Enter your email and we will sent you a password reset'),
            //email textfield
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MyTextField(
                controller: emailController,
                hintText: 'Email',
                obsureText: false,
              ),
            ),
            const SizedBox(height: 10),
          MaterialButton(
            onPressed: () {
              passwordReset();
            },
            child: Text('Reset Password'),
            color: Colors.deepPurple[200],
          ),
          ],
      ),
          
    );
  }
}
