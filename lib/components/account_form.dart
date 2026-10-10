import 'package:flutter/material.dart';
import '../screen/forgot_password.dart';
import '../screen/home_page.dart';
import '../screen/login_screen.dart';
import '../screen/sign_up.dart';
import '../state/app_state.dart';
import '../services/cloud_backend.dart';
import 'app_theme.dart';
import 'botanical_widgets.dart';
import 'validators.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key, this.signUp = false});
  final bool signUp;
  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  Future<void> _continue() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.signUp) {
        await state.signUp(_name.text, _email.text, _password.text);
      } else {
        await state.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      replaceWith(context, const HomePage());
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(widget.signUp
              ? 'Your green chapter begins'
              : 'Welcome back, plant person'),
          const SizedBox(height: 12),
          Text(
              widget.signUp
                  ? 'Let’s grow\nsomething good.'
                  : 'Good to see\nyou growing.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          Text(
              widget.signUp
                  ? 'A space for your plants, your favorites, and a little everyday inspiration.'
                  : 'Your favorite plants and greener routines are waiting for you.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
          if (widget.signUp) ...[
            TextFormField(
                key: const ValueKey('name-field'),
                controller: _name,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null),
            const SizedBox(height: 16),
          ],
          TextFormField(
              key: const ValueKey('email-field'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.alternate_email_rounded)),
              validator: validateEmail),
          const SizedBox(height: 16),
          TextFormField(
              key: const ValueKey('password-field'),
              controller: _password,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _continue(),
              validator: widget.signUp
                  ? validatePassword
                  : (value) => value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
              decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined)))),
          if (!widget.signUp)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => openPage(context, const ForgetScreen()),
                    child: const Text('Forgot password?'))),
          if (widget.signUp)
            const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Use at least 8 characters for your password.')),
          const SizedBox(height: 20),
          PlantButton(
              label: widget.signUp ? 'Create account' : 'Sign in',
              busy: _busy,
              onPressed: _busy ? null : _continue),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 18),
          const SizedBox(height: 20),
          Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(widget.signUp
                    ? 'Already have an account?'
                    : 'New to Plantify?'),
                TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (widget.signUp) {
                              replaceWith(context, const LoginScreen());
                            } else {
                              openPage(context, const SignUpScreen());
                            }
                          },
                    child: Text(widget.signUp ? 'Sign in' : 'Create account')),
              ]),
          const SizedBox(height: 12),
          SurfaceBox(
              padding: const EdgeInsets.all(14),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded,
                    size: 17, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text(
                        'Your garden, wherever you grow. Sign in to keep favorites and care notes together across your devices.',
                        style: TextStyle(fontSize: 11, height: 1.6))),
              ])),
        ]));
    return Scaffold(
        body: SafeArea(child: LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 850;
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Reveal(
                      child: Column(children: [
                    Row(children: [
                      if (Navigator.of(context).canPop()) const BackButton(),
                      const Wordmark()
                    ]),
                    const SizedBox(height: 36),
                    if (wide)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: SizedBox(
                                        height: 670,
                                        child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(
                                                  'assets/botanical/greenhouse-hero.webp',
                                                  fit: BoxFit.cover,
                                                  alignment:
                                                      Alignment.centerRight),
                                              const DecoratedBox(
                                                  decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                          begin:
                                                              Alignment.center,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                    Colors.transparent,
                                                    Color(0xE6183F32)
                                                  ]))),
                                              const Positioned(
                                                  left: 32,
                                                  right: 32,
                                                  bottom: 36,
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Eyebrow(
                                                            'A little green changes everything',
                                                            color:
                                                                Botanical.lime),
                                                        SizedBox(height: 14),
                                                        Text(
                                                            'Find your plant.\nFind your calm.',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'DMSerifDisplay',
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 42,
                                                                height: 1.15)),
                                                      ])),
                                            ])))),
                            const SizedBox(width: 70),
                            Expanded(child: form),
                          ])
                    else
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: form),
                  ])))));
    })));
  }
}
