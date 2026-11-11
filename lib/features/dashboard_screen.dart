import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../services/pim_service.dart';
import 'screen_helpers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  bool loading = true;
  String? error;
  List<dynamic> summary = [], overdue = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final s = ref.read(pimServiceProvider);
      final r = await Future.wait([
        s.list('/relatorios/resumo-por-colaborador'),
        s.list('/relatorios/atrasadas')
      ]);
      setState(() {
        summary = r[0];
        overdue = r[1];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = ref.read(apiClientProvider).message(e);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = {'Pendentes': 0, 'EmAndamento': 0, 'Concluidas': 0};
    for (final x in summary) {
      totals['Pendentes'] =
          (totals['Pendentes'] ?? 0) + (x['pendentes'] as num).toInt();
      totals['EmAndamento'] =
          (totals['EmAndamento'] ?? 0) + (x['emAndamento'] as num).toInt();
      totals['Concluidas'] =
          (totals['Concluidas'] ?? 0) + (x['concluidas'] as num).toInt();
    }
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          pageTitle(context, 'Painel de tarefas'),
          if (error != null) errorBox(context, error!),
          if (loading) const LinearProgressIndicator(),
          Column(children: [
            _stat('Pendentes', totals['Pendentes']!, const Color(0xff5c4400)),
            const SizedBox(height: 12),
            _stat('Em andamento', totals['EmAndamento']!,
                const Color(0xff0b3a75)),
            const SizedBox(height: 12),
            _stat('Concluídas', totals['Concluidas']!, const Color(0xff0d4a14)),
            const SizedBox(height: 12),
            _stat('Atrasadas', overdue.length, const Color(0xffa4001c))
          ]),
          const SizedBox(height: 22),
          const Text('Por colaborador',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (summary.isEmpty && !loading)
            const Text('Nenhum colaborador ativo.'),
          ...summary.map((x) => Card(
              child: ListTile(
                  title: Text('${x['colaboradorNome']}'),
                  subtitle: Text(
                      '${x['concluidas']} de ${x['total']} concluídas (${x['pendentes']} pendentes, ${x['emAndamento']} em andamento)'),
                  trailing: SizedBox(
                      width: 60,
                      child: Text(
                          '${x['total'] == 0 ? 0 : ((x['concluidas'] as num) / (x['total'] as num) * 100).round()}%'))))),
          const SizedBox(height: 18),
          const Text('Tarefas atrasadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (overdue.isEmpty && !loading)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma tarefa atrasada. 🎉')),
          ...overdue.map((t) => Card(
              child: ListTile(
                  title: Text('${t['titulo']}'),
                  subtitle: Text(
                      '${t['colaboradorNome'] ?? 'Sem responsável'} · ${dateText(t['dataPrazo'])} · ${t['diasAtraso']} dias de atraso'),
                  onTap: () => context.push('/tarefa/${t['id']}'))))
        ]));
  }

  Widget _stat(String title, int count, Color color) => SizedBox(
      width: double.infinity,
      child: Card(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : color.withOpacity(.08),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xffffff00)
                                    : color)),
                    Text('$count',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xffffff00)
                                    : color))
                  ]))));
}
