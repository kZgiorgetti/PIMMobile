import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../providers/session_provider.dart';
import '../services/pim_service.dart';
import 'screen_helpers.dart';

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
      pageTitle(context, t?['titulo'] ?? 'Detalhe da tarefa',
          action: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back))),
      if (error != null) errorBox(context, error!),
      if (loading) const LinearProgressIndicator(),
      if (t != null) ...[
        Wrap(spacing: 8, children: [
          badge(context, labelStatus('${t['status']}'),
              color: statusColor('${t['status']}')),
          badge(context, labelPriority('${t['prioridade']}')),
          if (t['atrasada'] == true)
            badge(context, 'Atrasada', color: const Color(0xffa4001c))
        ]),
        const SizedBox(height: 12),
        Text('${t['descricao'] ?? 'Sem descrição.'}'),
        const SizedBox(height: 12),
        Text('Responsável: ${t['colaboradorNome'] ?? 'Sem responsável'}'),
        Text('Equipe: ${t['equipeNome'] ?? '—'}'),
        Text('Prazo: ${dateText(t['dataPrazo'])}'),
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
                '${h['usuarioId'] == null ? '' : 'Usuário #${h['usuarioId']} · '}${dateText(h['dataAlteracao'])}'))),
        const Divider(height: 28),
        const Text('Comentários',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (comments.isEmpty) const Text('Nenhum comentário ainda.'),
        ...comments.map((c) => Card(
            child: ListTile(
                title: Text('${c['usuarioNome'] ?? 'Usuário'}'),
                subtitle:
                    Text('${c['texto']}\n${dateText(c['dataCriacao'])}')))),
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
