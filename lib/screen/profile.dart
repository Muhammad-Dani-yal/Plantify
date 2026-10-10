import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../services/cloud_backend.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'start_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loaded = false, _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _name.text = AppScope.of(context).name;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showMessage(context, message);
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PageBody(maxWidth: 760, children: [
      const Eyebrow('Your greener everyday'),
      const SizedBox(height: 10),
      Text('A space of your own.',
          style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 24),
      SurfaceBox(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(children: [
            CircleAvatar(
                radius: 30,
                backgroundColor: Botanical.forest,
                foregroundColor: Botanical.lime,
                child: Text(
                    state.name.isEmpty ? 'P' : state.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28))),
            const SizedBox(width: 18),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(state.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(state.email),
                  const SizedBox(height: 6),
                  Text(
                      state.emailVerified
                          ? 'Email verified'
                          : 'Email not verified yet',
                      style: const TextStyle(fontSize: 11)),
                ])),
          ])),
      const SizedBox(height: 18),
      if (!state.emailVerified)
        SurfaceBox(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
              'Verify your email to keep your account ready for recovery.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(state.sendVerification,
                        'Verification email sent. Check your inbox.'),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Send verification')),
            TextButton(
                onPressed: _busy
                    ? null
                    : () =>
                        _run(state.refreshAccount, 'Account status refreshed.'),
                child: const Text('I have verified')),
          ]),
        ])),
      const SizedBox(height: 18),
      SurfaceBox(
          child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                        key: const ValueKey('profile-name'),
                        controller: _name,
                        decoration:
                            const InputDecoration(labelText: 'Display name'),
                        textCapitalization: TextCapitalization.words,
                        maxLength: 60,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a display name'
                                : null),
                    const SizedBox(height: 12),
                    PlantButton(
                        label: 'Save profile',
                        icon: Icons.check_rounded,
                        busy: _busy,
                        onPressed: _busy
                            ? null
                            : () {
                                if (_form.currentState!.validate()) {
                                  _run(() => state.updateProfile(_name.text),
                                      'Profile saved.');
                                }
                              }),
                  ]))),
      const SizedBox(height: 18),
      SurfaceBox(
          child: Column(children: [
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode'),
            subtitle: const Text('A softer glow for evening exploring'),
            value: state.darkMode,
            onChanged: state.setDarkMode),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Care hints'),
            subtitle: const Text('Show growing tips in My Plants'),
            value: state.careHints,
            onChanged: state.setCareHints),
      ])),
      const SizedBox(height: 18),
      Text(
          '${state.favorites.length} favourites · ${state.garden.length} plants in your garden'),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            state.pendingSync
                ? Icons.sync
                : state.offline
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_done_outlined,
            size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(state.pendingSync
                ? 'Saving your latest changes…'
                : state.offline
                    ? 'Showing cached data. Changes will sync when the connection returns.'
                    : 'Your garden and favourites sync with your account.')),
      ]),
      const SizedBox(height: 24),
      Wrap(spacing: 10, runSpacing: 10, children: [
        OutlinedButton.icon(
            onPressed: () => openPage(context, const StartPage()),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Welcome tour')),
        OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await _run(state.logout, 'Signed out.');
                    if (context.mounted && !state.activeSession) {
                      replaceWith(context, const LoginScreen());
                    }
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out')),
      ]),
    ]);
  }
}
