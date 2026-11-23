import 'package:flutter/material.dart';

import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_objects.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import '../more/privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'employee@demo.com');
  final _passwordController = TextEditingController(text: 'demo1234');
  late final TextEditingController _urlController;
  bool _obscurePassword = true;
  bool _showServerSettings = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.appState.backendUrl);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);
    try {
      await widget.appState.updateBackendUrl(_urlController.text);
      await widget.appState.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _localError = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.appState.isBusy;

    return Scaffold(
      body: KeystoneBackdrop(
        warmAccent: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const KeystoneAppBadge(size: 40),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: KeystoneLogo(size: 20),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Employee portal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: KeystoneColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const KeystoneBadge(
                          label: 'Secure Sign-In',
                          tone: BadgeTone.emerald,
                          dotColor: KeystoneColors.emerald,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const LoginHeroObjects(),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [KeystoneColors.ink, KeystoneColors.pine, Color(0xFF15803D)],
                        stops: [0.0, 0.55, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'Your workday, in one workspace.',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.55,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Punch attendance, check payslips, apply for leave, and log field visits.',
                      style: TextStyle(fontSize: 13.5, color: KeystoneColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    KeystoneCard(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Work email',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: KeystoneColors.ink),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'you@company.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded, size: 18, color: KeystoneColors.muted),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty || !v.contains('@')) {
                                  return 'Enter a valid work email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Password',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: KeystoneColors.ink),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: KeystoneColors.muted),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: KeystoneColors.muted,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your password';
                                return null;
                              },
                            ),
                            if (_localError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: KeystoneColors.clayTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _localError!,
                                      style: const TextStyle(fontSize: 12.5, color: KeystoneColors.clay, fontWeight: FontWeight.w500),
                                    ),
                                    if (_localError!.contains('server') ||
                                        _localError!.contains('timed out') ||
                                        _localError!.contains('connect') ||
                                        _localError!.contains('network')) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _emailController.text = 'employee@demo.com';
                                          _passwordController.text = 'demo1234';
                                          _submit();
                                        },
                                        child: const Text(
                                          '→ Tap to sign in with Demo Account',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: KeystoneColors.pine,
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            KeystoneGradientButton(
                              onPressed: isBusy ? null : _submit,
                              busy: isBusy,
                              icon: Icons.login_rounded,
                              label: 'Sign in',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _showServerSettings = !_showServerSettings),
                          icon: Icon(
                            _showServerSettings ? Icons.expand_less : Icons.dns_outlined,
                            size: 16,
                            color: KeystoneColors.muted,
                          ),
                          label: const Text(
                            'Server address',
                            style: TextStyle(fontSize: 12.5, color: KeystoneColors.muted),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            );
                          },
                          icon: const Icon(Icons.shield_outlined, size: 15, color: KeystoneColors.pine),
                          label: const Text(
                            'Privacy policy',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: KeystoneColors.pine),
                          ),
                        ),
                      ],
                    ),
                    if (_showServerSettings) ...[
                      const SizedBox(height: 8),
                      KeystoneCard(
                        backgroundColor: KeystoneColors.surface.withValues(alpha: 0.92),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Workspace API URL',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KeystoneColors.ink),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                hintText: 'https://api.yourcompany.com',
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your organization’s Keystone HTTPS server endpoint.',
                              style: TextStyle(fontSize: 11.5, color: KeystoneColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
