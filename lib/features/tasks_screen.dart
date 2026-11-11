import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../providers/session_provider.dart';
import '../services/pim_service.dart';
import 'screen_helpers.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksState();
}

class _TasksState extends ConsumerState<TasksScreen> {
  List<dynamic> items = [], collaborators = [], teams = [];
  int page = 1, total = 0;
  String search = '', status = '', priority = '', colab = '';
  bool loading = true;
  String? error;
  final searchController = TextEditingController();
  bool get manager =>
      ['Admin', 'Gestor'].contains(ref.read(sessionProvider)?['perfil']);
  @override
  void initState() {
    super.initState();
    load();
    if (manager) {
      ref
          .read(pimServiceProvider)
          .list('/colaboradores', query: {'apenasAtivos': true}).then((v) {
        if (mounted) setState(() => collaborators = v);
      });
      ref.read(pimServiceProvider).list('/equipes').then((v) {
        if (mounted) setState(() => teams = v);
      });
    }
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final data = await ref.read(pimServiceProvider).get('/tarefas', query: {
        'busca': search,
        'status': status,
        'prioridade': priority,
        'colaboradorId': colab,
        'page': page,
        'pageSize': 10
      });
      setState(() {
        items = data['itens'] as List<dynamic>;
        total = (data['total'] as num).toInt();
        error = null;
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
  Widget build(BuildContext context) => RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        pageTitle(context, manager ? 'Tarefas' : 'Minhas tarefas',
            action: manager
                ? FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova tarefa'))
                : null),
        TextField(
            controller: searchController,
            decoration: InputDecoration(
                labelText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: () {
                      searchController.clear();
                      search = '';
                      page = 1;
                      load();
                    },
                    icon: const Icon(Icons.clear))),
            onSubmitted: (v) {
              search = v.trim();
              page = 1;
              load();
            }),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 8, children: [
          _choice(
              'Status', status, ['', 'Pendente', 'EmAndamento', 'Concluida'],
              (v) {
            status = v;
            page = 1;
            load();
          }),
          _choice(
              'Prioridade', priority, ['', 'Baixa', 'Media', 'Alta', 'Urgente'],
              (v) {
            priority = v;
            page = 1;
            load();
          }),
          if (manager && collaborators.isNotEmpty)
            _choice('Pessoa', colab,
                ['', ...collaborators.map((x) => '${x['id']}')], (v) {
              colab = v;
              page = 1;
              load();
            }, labels: [
              'Todas as pessoas',
              ...collaborators.map((x) => '${x['nome']}')
            ])
        ]),
        const SizedBox(height: 20),
        if (error != null) errorBox(context, error!),
        if (loading) const LinearProgressIndicator(),
        if (items.isEmpty && !loading)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhuma tarefa encontrada.',
                  textAlign: TextAlign.center)),
        ...items.map((t) => Card(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('${t['titulo']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17))),
                        PopupMenuButton<String>(
                            onSelected: (v) => _action(v, t),
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'details',
                                      child: Text('Ver detalhes')),
                                  if (t['status'] != 'Concluida')
                                    const PopupMenuItem(
                                        value: 'done', child: Text('Concluir')),
                                  if (manager) ...const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Editar')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Excluir'))
                                  ]
                                ])
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        badge(context, labelStatus('${t['status']}'),
                            color: statusColor('${t['status']}')),
                        badge(context, labelPriority('${t['prioridade']}')),
                        if (t['atrasada'] == true)
                          badge(context, 'Atrasada',
                              color: const Color(0xffa4001c))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          '${t['colaboradorNome'] ?? 'Sem responsável'} · Prazo: ${dateText(t['dataPrazo'])}',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xffd0d0d0)
                                  : const Color(0xff526b71)))
                    ])))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          OutlinedButton(
              onPressed: page > 1
                  ? () {
                      page--;
                      load();
                    }
                  : null,
              child: const Text('Anterior')),
          Text(
              'Página $page de ${((total + 9) ~/ 10).clamp(1, 999)} ($total tarefas)'),
          OutlinedButton(
              onPressed: page * 10 < total
                  ? () {
                      page++;
                      load();
                    }
                  : null,
              child: const Text('Próxima'))
        ])
      ]));
  Widget _choice(String label, String value, List<String> values,
          ValueChanged<String> onChanged, {List<String>? labels}) =>
      SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(labelText: label),
              items: List.generate(
                  values.length,
                  (i) => DropdownMenuItem(
                      value: values[i],
                      child: Text(
                          (labels ?? values)[i].isEmpty
                              ? 'Todos'
                              : (labels ?? values)[i],
                          overflow: TextOverflow.ellipsis))),
              onChanged: (v) {
                if (v != null) onChanged(v);
              }));
  Future<void> _action(String action, dynamic t) async {
    try {
      final s = ref.read(pimServiceProvider), id = '${t['id']}';
      if (action == 'details') {
        if (mounted) context.push('/tarefa/$id');
        return;
      }
      if (action == 'done') await s.post('/tarefas/$id/concluir');
      if (action == 'delete') {
        if (!await confirmDialog(
            context, 'Deseja realmente excluir esta tarefa?')) return;
        await s.delete('/tarefas/$id');
      }
      if (action == 'edit') await _edit(task: t);
      await load();
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
    }
  }

  Future<void> _edit({dynamic task}) async {
    final title = TextEditingController(text: task?['titulo'] ?? '');
    final desc = TextEditingController(text: task?['descricao'] ?? '');
    String p = task?['prioridade'] ?? 'Media';
    String cid = '${task?['colaboradorId'] ?? ''}',
        eid = '${task?['equipeId'] ?? ''}';
    DateTime? due;
    try {
      due = DateTime.parse('${task?['dataPrazo']}');
    } catch (_) {}
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    title: Text(task == null ? 'Nova tarefa' : 'Editar tarefa'),
                    content: SizedBox(
                        width: 450,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const SizedBox(height: 12),
                              TextField(
                                  controller: title,
                                  decoration: const InputDecoration(
                                      labelText: 'Título'),
                                  maxLength: 200),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: desc,
                                  decoration: const InputDecoration(
                                      labelText: 'Descrição'),
                                  maxLines: 4,
                                  maxLength: 2000),
                              const SizedBox(height: 12),
                              DropdownButtonFormField(
                                  value: p,
                                  decoration: const InputDecoration(
                                      labelText: 'Prioridade'),
                                  items: ['Baixa', 'Media', 'Alta', 'Urgente']
                                      .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(labelPriority(v))))
                                      .toList(),
                                  onChanged: (v) => set(() => p = v!)),
                              if (manager) const SizedBox(height: 24),
                              if (manager)
                                DropdownButtonFormField<String>(
                                    value: cid.isEmpty ? '' : cid,
                                    decoration: const InputDecoration(
                                        labelText: 'Pessoa responsável'),
                                    items: [
                                      const DropdownMenuItem(
                                          value: '',
                                          child: Text('Sem responsável')),
                                      ...collaborators.map((c) =>
                                          DropdownMenuItem(
                                              value: '${c['id']}',
                                              child: Text('${c['nome']}')))
                                    ],
                                    onChanged: (v) => set(() => cid = v ?? '')),
                              if (manager) const SizedBox(height: 24),
                              if (manager)
                                DropdownButtonFormField<String>(
                                    value: eid.isEmpty ? '' : eid,
                                    decoration: const InputDecoration(
                                        labelText: 'Equipe'),
                                    items: [
                                      const DropdownMenuItem(
                                          value: '', child: Text('Sem equipe')),
                                      ...teams.map((team) => DropdownMenuItem(
                                          value: '${team['id']}',
                                          child: Text('${team['nome']}')))
                                    ],
                                    onChanged: (v) => set(() => eid = v ?? '')),
                              const SizedBox(height: 12),
                              ListTile(
                                  title: Text(due == null
                                      ? 'Prazo: —'
                                      : 'Prazo: ${dateText(due!.toIso8601String())}'),
                                  trailing: const Icon(Icons.calendar_month),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                        context: ctx,
                                        initialDate: due ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100));
                                    if (d != null) set(() => due = d);
                                  })
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, {
                                'titulo': title.text.trim(),
                                'descricao': desc.text,
                                'prioridade': p,
                                'dataPrazo': due == null
                                    ? null
                                    : '${due!.toIso8601String().substring(0, 10)}T23:59:00Z',
                                'colaboradorId':
                                    cid.isEmpty ? null : int.tryParse(cid),
                                'equipeId':
                                    eid.isEmpty ? null : int.tryParse(eid)
                              }),
                          child: const Text('Salvar'))
                    ])));
    if (result == null) return;
    if (result['titulo'].toString().isEmpty) {
      setState(() => error = 'Informe o título da tarefa.');
      return;
    }
    if (task == null)
      await ref.read(pimServiceProvider).post('/tarefas', result);
    else
      await ref.read(pimServiceProvider).put('/tarefas/${task['id']}', result);
  }
}
