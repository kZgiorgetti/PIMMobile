import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'services/pim_service.dart';
import 'features/screens.dart';
import 'providers/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(sessionProvider.notifier).restore();
  await container.read(accessibilityProvider.notifier).restore();
  container.read(apiClientProvider).onSessionExpired =
      container.read(sessionProvider.notifier).clear;
  runApp(
      UncontrolledProviderScope(container: container, child: const PimApp()));
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityController, ({bool contrast, int font})>(
        (_) => AccessibilityController());

class AccessibilityController
    extends StateNotifier<({bool contrast, int font})> {
  AccessibilityController() : super((contrast: false, font: 0));
  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    state =
        (contrast: p.getBool('contrast') ?? false, font: p.getInt('font') ?? 0);
  }

  Future<void> toggleContrast() async {
    final v = !state.contrast;
    state = (contrast: v, font: state.font);
    final p = await SharedPreferences.getInstance();
    await p.setBool('contrast', v);
  }

  Future<void> fontBy(int d) async {
    final v = (state.font + d).clamp(0, 3).toInt();
    state = (contrast: state.contrast, font: v);
    final p = await SharedPreferences.getInstance();
    await p.setInt('font', v);
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final logged = session != null;
        final login = state.matchedLocation == '/login';
        if (!logged && !login) return '/login';
        if (logged && login)
          return session['perfil'] == 'Colaborador' ? '/tarefas' : '/painel';
        if (logged) {
          final role = session['perfil'];
          final path = state.matchedLocation;
          if (path == '/painel' && role == 'Colaborador') return '/tarefas';
          if ((path == '/colaboradores' || path == '/equipes') &&
              !['Admin', 'Gestor'].contains(role)) return '/tarefas';
          if (path == '/usuarios' && role != 'Admin') return '/tarefas';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        ShellRoute(builder: (c, s, child) => AppShell(child: child), routes: [
          GoRoute(path: '/painel', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/tarefas', builder: (_, __) => const TasksScreen()),
          GoRoute(
              path: '/tarefa/:id',
              builder: (_, s) => TaskDetailScreen(id: s.pathParameters['id']!)),
          GoRoute(
              path: '/colaboradores',
              builder: (_, __) =>
                  const ManagementScreen(kind: 'colaboradores')),
          GoRoute(
              path: '/equipes',
              builder: (_, __) => const ManagementScreen(kind: 'equipes')),
          GoRoute(
              path: '/usuarios',
              builder: (_, __) => const ManagementScreen(kind: 'usuarios')),
        ])
      ]);
});

class PimApp extends ConsumerWidget {
  const PimApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(accessibilityProvider);
    return MaterialApp.router(
        title: 'Almoxarifado',
        debugShowCheckedModeBanner: false,
        theme: appTheme(a.contrast, a.font),
        routerConfig: ref.watch(_routerProvider));
  }
}

ThemeData appTheme(bool contrast, int font) {
  final primary = contrast ? const Color(0xffffff00) : const Color(0xff07535f);
  final bg = contrast ? Colors.black : const Color(0xfff5fbfc);
  final surface = contrast ? const Color(0xff0d0d0d) : const Color(0xffe8f6f8);
  final fg = contrast ? Colors.white : const Color(0xff17343a);
  return ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.light(
          primary: primary,
          onPrimary: contrast ? Colors.black : Colors.white,
          surface: surface,
          onSurface: fg,
          error: contrast ? const Color(0xffff8080) : const Color(0xffa4001c)),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      textTheme: ThemeData.light().textTheme.apply(
          fontSizeFactor: 1.0 + [0.0, .125, .25, .5][font],
          bodyColor: fg,
          displayColor: fg),
      appBarTheme: AppBarTheme(
          backgroundColor: contrast ? Colors.black : const Color(0xff07535f),
          foregroundColor: Colors.white,
          elevation: 0),
      cardTheme: CardThemeData(
          color: surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: contrast ? Colors.white : const Color(0xffc5dfe3)))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                  color: contrast ? Colors.white : const Color(0xffc5dfe3)))));
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final isAdmin = user['perfil'] == 'Admin',
        isManager = isAdmin || user['perfil'] == 'Gestor';
    final items = <({String path, String label, IconData icon})>[
      if (isManager)
        (path: '/painel', label: 'Painel', icon: Icons.dashboard_outlined),
      (
        path: '/tarefas',
        label: user['perfil'] == 'Colaborador' ? 'Minhas tarefas' : 'Tarefas',
        icon: Icons.task_alt
      ),
      if (isManager)
        (
          path: '/colaboradores',
          label: 'Colaboradores',
          icon: Icons.people_outline
        ),
      if (isManager)
        (path: '/equipes', label: 'Equipes', icon: Icons.groups_outlined),
      if (isAdmin)
        (
          path: '/usuarios',
          label: 'Usuários',
          icon: Icons.manage_accounts_outlined
        )
    ];
    final current = GoRouterState.of(context).matchedLocation;
    return Scaffold(
        appBar: AppBar(title: const Text('Almoxarifado'), actions: [
          if (MediaQuery.sizeOf(context).width > 650)
            Center(child: Text('Olá, ${user['nome']} (${user['perfil']})  ')),
          PopupMenuButton<String>(
              tooltip: 'Preferências e conta',
              itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'contrast',
                        child: Text('Alternar alto contraste')),
                    PopupMenuItem(
                        value: 'font+', child: Text('Aumentar letra')),
                    PopupMenuItem(
                        value: 'font-', child: Text('Diminuir letra')),
                    PopupMenuItem(value: 'logout', child: Text('Sair'))
                  ],
              onSelected: (v) async {
                if (v == 'contrast') {
                  await ref
                      .read(accessibilityProvider.notifier)
                      .toggleContrast();
                } else if (v == 'font+' || v == 'font-') {
                  await ref
                      .read(accessibilityProvider.notifier)
                      .fontBy(v == 'font+' ? 1 : -1);
                } else if (v == 'logout') {
                  try {
                    await ref.read(pimServiceProvider).logout();
                  } catch (_) {
                    await ref.read(apiClientProvider).clearTokens();
                  }
                  ref.read(sessionProvider.notifier).clear();
                  if (context.mounted) context.go('/login');
                }
              })
        ]),
        drawer: MediaQuery.sizeOf(context).width <= 650
            ? Drawer(
                child: ListView(children: [
                DrawerHeader(
                    child: Text('Olá, ${user['nome']}\n${user['perfil']}',
                        style: Theme.of(context).textTheme.titleLarge)),
                ...items.map((i) => ListTile(
                    leading: Icon(i.icon),
                    title: Text(i.label),
                    selected: current == i.path,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(i.path);
                    }))
              ]))
            : null,
        body: Row(children: [
          if (MediaQuery.sizeOf(context).width > 650)
            NavigationRail(
                selectedIndex: items
                    .indexWhere((i) => current == i.path)
                    .clamp(0, items.length - 1)
                    .toInt(),
                onDestinationSelected: (i) => context.go(items[i].path),
                labelType: NavigationRailLabelType.all,
                destinations: items
                    .map((i) => NavigationRailDestination(
                        icon: Icon(i.icon), label: Text(i.label)))
                    .toList()),
          Expanded(child: child)
        ]));
  }
}
