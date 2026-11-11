import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../providers/session_provider.dart';
import '../services/pim_service.dart';

String labelStatus(String s) => ({
      'Pendente': 'Pendente',
      'EmAndamento': 'Em andamento',
      'Concluida': 'Concluída'
    }[s] ??
    s);
String labelPriority(String s) => ({
      'Baixa': 'Baixa',
      'Media': 'Média',
      'Alta': 'Alta',
      'Urgente': 'Urgente'
    }[s] ??
    s);
Color statusColor(String s) => s == 'Concluida'
    ? const Color(0xff0d4a14)
    : s == 'EmAndamento'
        ? const Color(0xff0b3a75)
        : const Color(0xff5c4400);
Widget badge(String text, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: (color ?? const Color(0xff07535f)).withOpacity(.1),
        border: Border.all(color: color ?? const Color(0xff07535f)),
        borderRadius: BorderRadius.circular(30)),
    child: Text(text,
        style: TextStyle(
            color: color ?? const Color(0xff07535f),
            fontWeight: FontWeight.w700,
            fontSize: 12)));
Widget pageTitle(String title, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff17343a)))),
      if (action != null) action
    ]));
Widget errorBox(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: const Color(0xfffde7ea),
        border: Border(left: BorderSide(color: Colors.red.shade900, width: 4)),
        borderRadius: BorderRadius.circular(4)),
    child: Text(text,
        style: TextStyle(
            color: Colors.red.shade900, fontWeight: FontWeight.w600)));

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
                                if (error != null) errorBox(error!),
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
          pageTitle('Painel de tarefas'),
          if (error != null) errorBox(error!),
          if (loading) const LinearProgressIndicator(),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _stat('Pendentes', totals['Pendentes']!, const Color(0xff5c4400)),
            _stat('Em andamento', totals['EmAndamento']!,
                const Color(0xff0b3a75)),
            _stat('Concluídas', totals['Concluidas']!, const Color(0xff0d4a14)),
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
                      '${t['colaboradorNome'] ?? 'Sem responsável'} · ${_date(t['dataPrazo'])} · ${t['diasAtraso']} dias de atraso'),
                  onTap: () => context.push('/tarefa/${t['id']}'))))
        ]));
  }

  Widget _stat(String title, int count, Color color) => SizedBox(
      width: 180,
      child: Card(
          color: color.withOpacity(.08),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color)),
                    Text('$count',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: color))
                  ]))));
}

String _date(dynamic value) {
  if (value == null) return '—';
  try {
    final d = DateTime.parse('$value');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return '—';
  }
}

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
        pageTitle(manager ? 'Tarefas' : 'Minhas tarefas',
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
        if (error != null) errorBox(error!),
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
                        badge(labelStatus('${t['status']}'),
                            color: statusColor('${t['status']}')),
                        badge(labelPriority('${t['prioridade']}')),
                        if (t['atrasada'] == true)
                          badge('Atrasada', color: const Color(0xffa4001c))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          '${t['colaboradorNome'] ?? 'Sem responsável'} · Prazo: ${_date(t['dataPrazo'])}',
                          style: const TextStyle(color: Color(0xff526b71)))
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
        if (!await _confirm(context, 'Deseja realmente excluir esta tarefa?'))
          return;
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
                              TextField(
                                  controller: title,
                                  decoration: const InputDecoration(
                                      labelText: 'Título'),
                                  maxLength: 200),
                              TextField(
                                  controller: desc,
                                  decoration: const InputDecoration(
                                      labelText: 'Descrição'),
                                  maxLines: 4,
                                  maxLength: 2000),
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
                              ListTile(
                                  title: Text(due == null
                                      ? 'Prazo: —'
                                      : 'Prazo: ${_date(due!.toIso8601String())}'),
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

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailState();
}

class _TaskDetailState extends ConsumerState<TaskDetailScreen> {
  Map<String, dynamic>? task;
  List<dynamic> comments = [], history = [], collaborators = [];
  bool loading = true;
  String? error;
  String status = 'Pendente', person = '';
  final comment = TextEditingController();
  bool get manager =>
      ['Admin', 'Gestor'].contains(ref.read(sessionProvider)?['perfil']);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final s = ref.read(pimServiceProvider);
      final r = await Future.wait([
        s.one('/tarefas/${widget.id}'),
        s.list('/tarefas/${widget.id}/comentarios'),
        s.list('/tarefas/${widget.id}/historico')
      ]);
      if (manager)
        collaborators =
            await s.list('/colaboradores', query: {'apenasAtivos': true});
      setState(() {
        task = Map<String, dynamic>.from(r[0] as Map);
        comments = r[1] as List<dynamic>;
        history = r[2] as List<dynamic>;
        status = '${task!['status']}';
        person = '${task!['colaboradorId'] ?? ''}';
        loading = false;
        error = null;
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
    final t = task;
    return ListView(padding: const EdgeInsets.all(20), children: [
      pageTitle(t?['titulo'] ?? 'Detalhe da tarefa',
          action: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back))),
      if (error != null) errorBox(error!),
      if (loading) const LinearProgressIndicator(),
      if (t != null) ...[
        Wrap(spacing: 8, children: [
          badge(labelStatus('${t['status']}'),
              color: statusColor('${t['status']}')),
          badge(labelPriority('${t['prioridade']}')),
          if (t['atrasada'] == true)
            badge('Atrasada', color: const Color(0xffa4001c))
        ]),
        const SizedBox(height: 12),
        Text('${t['descricao'] ?? 'Sem descrição.'}'),
        const SizedBox(height: 12),
        Text('Responsável: ${t['colaboradorNome'] ?? 'Sem responsável'}'),
        Text('Equipe: ${t['equipeNome'] ?? '—'}'),
        Text('Prazo: ${_date(t['dataPrazo'])}'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
              DropdownMenuItem(
                  value: 'EmAndamento', child: Text('Em andamento')),
              DropdownMenuItem(value: 'Concluida', child: Text('Concluída'))
            ],
            onChanged: (v) => setState(() => status = v!)),
        if (manager)
          DropdownButtonFormField<String>(
              value: person,
              decoration:
                  const InputDecoration(labelText: 'Pessoa responsável'),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Sem responsável')),
                ...collaborators.map((c) => DropdownMenuItem(
                    value: '${c['id']}', child: Text('${c['nome']}')))
              ],
              onChanged: (v) => setState(() => person = v ?? '')),
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
                onPressed: saveChanges, child: const Text('Confirmar'))),
        const Divider(height: 28),
        const Text('Histórico de status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (history.isEmpty) const Text('Sem alterações de status.'),
        ...history.map((h) => ListTile(
            dense: true,
            leading: const Icon(Icons.history),
            title: Text(
                '${labelStatus('${h['statusAnterior']}')} → ${labelStatus('${h['statusNovo']}')}'),
            subtitle: Text(
                '${h['usuarioId'] == null ? '' : 'Usuário #${h['usuarioId']} · '}${_date(h['dataAlteracao'])}'))),
        const Divider(height: 28),
        const Text('Comentários',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (comments.isEmpty) const Text('Nenhum comentário ainda.'),
        ...comments.map((c) => Card(
            child: ListTile(
                title: Text('${c['usuarioNome'] ?? 'Usuário'}'),
                subtitle: Text('${c['texto']}\n${_date(c['dataCriacao'])}')))),
        TextField(
            controller: comment,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Novo comentário')),
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
                onPressed: addComment, child: const Text('Comentar')))
      ]
    ]);
  }

  Future<void> saveChanges() async {
    try {
      final s = ref.read(pimServiceProvider);
      if (status != task?['status'])
        await s.patch('/tarefas/${widget.id}/status', {'status': status});
      if (manager && person != '${task?['colaboradorId'] ?? ''}')
        await s.post('/tarefas/${widget.id}/reatribuir',
            {'colaboradorId': person.isEmpty ? null : int.tryParse(person)});
      await load();
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
    }
  }

  Future<void> addComment() async {
    if (comment.text.trim().isEmpty) {
      setState(() => error = 'Escreva o comentário antes de enviar.');
      return;
    }
    try {
      await ref.read(pimServiceProvider).post(
          '/tarefas/${widget.id}/comentarios', {'texto': comment.text.trim()});
      comment.clear();
      await load();
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
    }
  }
}

class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key, required this.kind});
  final String kind;
  @override
  ConsumerState<ManagementScreen> createState() => _ManagementState();
}

class _ManagementState extends ConsumerState<ManagementScreen> {
  List<dynamic> rows = [], collaborators = [];
  bool loading = true;
  String? error;
  String get title => {
        'colaboradores': 'Colaboradores',
        'equipes': 'Equipes',
        'usuarios': 'Usuários'
      }[widget.kind]!;
  String get endpoint => {
        'colaboradores': '/colaboradores',
        'equipes': '/equipes',
        'usuarios': '/usuarios'
      }[widget.kind]!;
  bool get admin => widget.kind == 'usuarios';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      rows = await ref.read(pimServiceProvider).list(endpoint,
          query:
              widget.kind == 'colaboradores' ? {'apenasAtivos': false} : null);
      if (widget.kind != 'colaboradores')
        collaborators = await ref
            .read(pimServiceProvider)
            .list('/colaboradores', query: {'apenasAtivos': true});
      setState(() {
        loading = false;
        error = null;
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
        pageTitle(title,
            action: FilledButton.icon(
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: Text(
                    'Novo ${widget.kind == 'equipes' ? 'equipe' : widget.kind == 'usuarios' ? 'usuário' : 'colaborador'}'))),
        if (error != null) errorBox(error!),
        if (loading) const LinearProgressIndicator(),
        if (rows.isEmpty && !loading) const Text('Nenhum registro cadastrado.'),
        ...rows.map((x) => Card(
            child: ListTile(
                title: Text('${x['nome']}'),
                subtitle: Text(widget.kind == 'colaboradores'
                    ? '${x['email'] ?? '—'} · ${x['cargo'] ?? '—'} · ${x['ativo'] == true ? 'Ativo' : 'Inativo'}'
                    : widget.kind == 'usuarios'
                        ? '${x['email']} · ${x['perfil']} · ${x['ativo'] == true ? 'Ativo' : 'Inativo'}'
                        : '${x['descricao'] ?? 'Sem descrição.'}\n${(x['membros'] as List? ?? []).map((m) => m['nome']).join(', ')}'),
                isThreeLine: widget.kind == 'equipes',
                trailing: PopupMenuButton<String>(
                    onSelected: (v) => action(v, x),
                    itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Editar')),
                          if (widget.kind == 'equipes')
                            const PopupMenuItem(
                                value: 'member',
                                child: Text('Adicionar membro')),
                          if (widget.kind == 'usuarios') ...const [
                            PopupMenuItem(
                                value: 'password',
                                child: Text('Redefinir senha'))
                          ],
                          if (widget.kind == 'usuarios' &&
                              x['id'] != ref.read(sessionProvider)?['id'])
                            const PopupMenuItem(
                                value: 'toggle',
                                child: Text('Ativar / inativar')),
                          if (widget.kind == 'equipes')
                            const PopupMenuItem(
                                value: 'remove-member',
                                child: Text('Remover membro')),
                          if (widget.kind == 'colaboradores' ||
                              widget.kind == 'equipes')
                            const PopupMenuItem(
                                value: 'delete', child: Text('Excluir'))
                        ]))))
      ]));
  Future<void> edit({dynamic row}) async {
    final name = TextEditingController(text: row?['nome'] ?? ''),
        email = TextEditingController(text: row?['email'] ?? ''),
        extra = TextEditingController(
            text: widget.kind == 'colaboradores'
                ? (row?['cargo'] ?? '')
                : (row?['descricao'] ?? '')),
        pass = TextEditingController();
    String profile = row?['perfil'] ?? 'Colaborador';
    final data = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    title: Text('${row == null ? 'Novo' : 'Editar'} $title'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nome')),
                      if (widget.kind != 'equipes')
                        TextField(
                            controller: email,
                            decoration:
                                const InputDecoration(labelText: 'E-mail')),
                      if (widget.kind == 'colaboradores')
                        TextField(
                            controller: extra,
                            decoration:
                                const InputDecoration(labelText: 'Cargo')),
                      if (widget.kind == 'equipes')
                        TextField(
                            controller: extra,
                            decoration:
                                const InputDecoration(labelText: 'Descrição'),
                            maxLines: 3),
                      if (admin && row == null)
                        TextField(
                            controller: pass,
                            decoration:
                                const InputDecoration(labelText: 'Senha'),
                            obscureText: true),
                      if (admin)
                        DropdownButtonFormField(
                            value: profile,
                            decoration:
                                const InputDecoration(labelText: 'Perfil'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Colaborador',
                                  child: Text('Colaborador')),
                              DropdownMenuItem(
                                  value: 'Gestor', child: Text('Gestor')),
                              DropdownMenuItem(
                                  value: 'Admin', child: Text('Admin'))
                            ],
                            onChanged: (v) => set(() => profile = v!))
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, {
                                'nome': name.text.trim(),
                                'email': email.text.trim(),
                                'cargo': widget.kind == 'colaboradores'
                                    ? extra.text.trim()
                                    : null,
                                'descricao': widget.kind == 'equipes'
                                    ? extra.text.trim()
                                    : null,
                                'senha': pass.text,
                                'perfil': profile
                              }),
                          child: const Text('Salvar'))
                    ])));
    if (data == null) return;
    try {
      if (data['nome'].toString().isEmpty) throw Exception('Informe o nome.');
      if (row == null) {
        final payload = widget.kind == 'colaboradores'
            ? {
                'nome': data['nome'],
                'email':
                    (data['email'] as String).isEmpty ? null : data['email'],
                'cargo':
                    (data['cargo'] as String).isEmpty ? null : data['cargo']
              }
            : widget.kind == 'equipes'
                ? {
                    'nome': data['nome'],
                    'descricao': (data['descricao'] as String).isEmpty
                        ? null
                        : data['descricao']
                  }
                : {
                    'nome': data['nome'],
                    'email': data['email'],
                    'senha': data['senha'],
                    'perfil': data['perfil']
                  };
        await ref.read(pimServiceProvider).post(endpoint, payload);
      } else {
        await ref.read(pimServiceProvider).put(
            '$endpoint/${row['id']}',
            widget.kind == 'colaboradores'
                ? {
                    'nome': data['nome'],
                    'email': (data['email'] as String).isEmpty
                        ? null
                        : data['email'],
                    'cargo':
                        (data['cargo'] as String).isEmpty ? null : data['cargo']
                  }
                : widget.kind == 'equipes'
                    ? {
                        'nome': data['nome'],
                        'descricao': (data['descricao'] as String).isEmpty
                            ? null
                            : data['descricao']
                      }
                    : {
                        'nome': data['nome'],
                        'email': data['email'],
                        'perfil': data['perfil']
                      });
      }
      await load();
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
    }
  }

  Future<void> action(String v, dynamic x) async {
    final s = ref.read(pimServiceProvider), id = '${x['id']}';
    try {
      switch (v) {
        case 'edit':
          await edit(row: x);
          return;
        case 'delete':
          if (await _confirm(context,
              'Deseja excluir ${widget.kind == 'equipes' ? 'esta equipe?' : 'este colaborador?'}'))
            await s.delete('$endpoint/$id');
          break;
        case 'toggle':
          if (x['ativo'] == true) {
            if (!await _confirm(context,
                'Inativar este usuário? Ele não poderá mais entrar no sistema.'))
              return;
            await s.post('/usuarios/$id/inativar');
          } else {
            await s.post('/usuarios/$id/ativar');
          }
          break;
        case 'password':
          await _resetPassword(x);
          break;
        case 'member':
          await _addMember(x);
          break;
        case 'remove-member':
          await _removeMember(x);
          break;
      }
      await load();
    } catch (e) {
      setState(() => error = ref.read(apiClientProvider).message(e));
    }
  }

  Future<void> _resetPassword(dynamic x) async {
    final p = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Redefinir senha'),
                content: TextField(
                    controller: p,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Redefinir'))
                ]));
    if (ok == true)
      await ref
          .read(pimServiceProvider)
          .post('/usuarios/${x['id']}/redefinir-senha', {'novaSenha': p.text});
  }

  Future<void> _removeMember(dynamic team) async {
    final members = List<dynamic>.from(team['membros'] as List? ?? []);
    if (members.isEmpty) {
      setState(() => error = 'Esta equipe não possui membros.');
      return;
    }
    String chosen = '${members.first['id']}';
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    title: const Text('Remover pessoa da equipe'),
                    content: DropdownButtonFormField(
                        value: chosen,
                        items: members
                            .map((m) => DropdownMenuItem(
                                value: '${m['id']}',
                                child: Text('${m['nome']}')))
                            .toList(),
                        onChanged: (v) => set(() => chosen = v!)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remover'))
                    ])));
    if (ok == true)
      await ref
          .read(pimServiceProvider)
          .delete('/equipes/${team['id']}/colaboradores/$chosen');
  }

  Future<void> _addMember(dynamic team) async {
    final members =
        (team['membros'] as List? ?? []).map((m) => m['id']).toSet();
    final free =
        collaborators.where((c) => !members.contains(c['id'])).toList();
    if (free.isEmpty) {
      setState(
          () => error = 'Não há colaboradores disponíveis para adicionar.');
      return;
    }
    String chosen = '${free.first['id']}';
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    title: const Text('Adicionar pessoa à equipe'),
                    content: DropdownButtonFormField(
                        value: chosen,
                        items: free
                            .map((c) => DropdownMenuItem(
                                value: '${c['id']}',
                                child: Text('${c['nome']}')))
                            .toList(),
                        onChanged: (v) => set(() => chosen = v!)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Adicionar'))
                    ])));
    if (ok == true)
      await ref
          .read(pimServiceProvider)
          .post('/equipes/${team['id']}/colaboradores/$chosen');
  }
}

Future<bool> _confirm(BuildContext context, String message) async =>
    (await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Confirmar ação'),
                content: Text(message),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar'))
                ]))) ??
    false;
