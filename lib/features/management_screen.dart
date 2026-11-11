import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../providers/session_provider.dart';
import '../services/pim_service.dart';
import 'screen_helpers.dart';

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
  String get createLabel => {
        'colaboradores': 'Novo colaborador',
        'equipes': 'Nova equipe',
        'usuarios': 'Novo usuário'
      }[widget.kind]!;
  String get itemLabel => {
        'colaboradores': 'colaborador',
        'equipes': 'equipe',
        'usuarios': 'usuário'
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
        pageTitle(context, title,
            action: FilledButton.icon(
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: Text(createLabel))),
        if (error != null) errorBox(context, error!),
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
                    title:
                        Text(row == null ? createLabel : 'Editar $itemLabel'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nome')),
                      const SizedBox(height: 16),
                      if (widget.kind != 'equipes')
                        TextField(
                            controller: email,
                            decoration:
                                const InputDecoration(labelText: 'E-mail')),
                      if (widget.kind != 'equipes') const SizedBox(height: 16),
                      if (widget.kind == 'colaboradores')
                        TextField(
                            controller: extra,
                            decoration:
                                const InputDecoration(labelText: 'Cargo')),
                      if (widget.kind == 'colaboradores')
                        const SizedBox(height: 16),
                      if (widget.kind == 'equipes')
                        TextField(
                            controller: extra,
                            decoration:
                                const InputDecoration(labelText: 'Descrição'),
                            maxLines: 3),
                      if (widget.kind == 'equipes') const SizedBox(height: 16),
                      if (admin && row == null)
                        TextField(
                            controller: pass,
                            decoration:
                                const InputDecoration(labelText: 'Senha'),
                            obscureText: true),
                      if (admin && row == null) const SizedBox(height: 16),
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
          if (await confirmDialog(context,
              'Deseja excluir ${widget.kind == 'equipes' ? 'esta equipe?' : 'este colaborador?'}'))
            await s.delete('$endpoint/$id');
          break;
        case 'toggle':
          if (x['ativo'] == true) {
            if (!await confirmDialog(context,
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
