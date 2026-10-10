import 'package:flutter/material.dart';
import '../components/botanical_widgets.dart';
import '../components/validators.dart';
import '../state/app_state.dart';
import '../services/cloud_backend.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({super.key});
  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitted = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _submitted = false;
    });
    try {
      await state.resetPassword(_email.text);
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const FittedBox(child: Wordmark())),
      body: PageBody(maxWidth: 440, children: [
        const SizedBox(height: 30),
        BrandMark(
            size: 70,
            color: Theme.of(context).colorScheme.primary,
            backdrop: Theme.of(context).colorScheme.secondaryContainer),
        const SizedBox(height: 26),
        const Eyebrow('A fresh start'),
        const SizedBox(height: 12),
        Text('Forgot your\npassword?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        const Text(
            'Enter the email you used for your account and we will help you get back to your garden.'),
        const SizedBox(height: 28),
        Form(
            key: _form,
            child: TextFormField(
                controller: _email,
                validator: validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded)))),
        const SizedBox(height: 22),
        PlantButton(
            label: 'Send reset link',
            busy: _busy,
            onPressed: _busy ? null : _submit,
            icon: Icons.mail_outline_rounded),
        if (_submitted)
          const Padding(
              padding: EdgeInsets.only(top: 20),
              child: SurfaceBox(
                  child: Text(
                      'If an account exists for this email, you will receive a password reset link. Check your inbox and spam folder.'))),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 18),
        Center(
            child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to sign in'))),
      ]));
}
