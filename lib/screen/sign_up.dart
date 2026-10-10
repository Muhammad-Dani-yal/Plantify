import 'package:flutter/material.dart';
import '../components/account_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) => const AccountForm(signUp: true);
}
