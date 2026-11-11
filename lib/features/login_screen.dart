import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../services/pim_service.dart';
import '../providers/session_provider.dart';
import 'screen_helpers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  String? error;
  bool loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Almoxarifado',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Entre com o seu e-mail e a sua senha.'),
                                const SizedBox(height: 18),
                                if (error != null) errorBox(context, error!),
                                TextField(
                                    controller: email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [
                                      AutofillHints.username
                                    ],
                                    decoration: const InputDecoration(
                                        labelText: 'E-mail')),
                                const SizedBox(height: 14),
                                TextField(
                                    controller: password,
                                    obscureText: true,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    decoration: const InputDecoration(
                                        labelText: 'Senha'),
                                    onSubmitted: (_) => submit()),
                                const SizedBox(height: 18),
                                FilledButton(
                                    onPressed: loading ? null : submit,
                                    child: loading
                                        ? const CircularProgressIndicator()
                                        : const Text('Entrar'))
                              ])))))));
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Informe o e-mail e a senha.');
      return;
    }
    setState(() => loading = true);
    try {
      final data = await ref
          .read(pimServiceProvider)
          .login(email.text.trim(), password.text);
      await ref.read(apiClientProvider).saveTokens(data);
      await ref
          .read(sessionProvider.notifier)
          .set(Map<String, dynamic>.from(data['usuario'] as Map));
      if (mounted)
        context.go(data['usuario']['perfil'] == 'Colaborador'
            ? '/tarefas'
            : '/painel');
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
      password.clear();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
