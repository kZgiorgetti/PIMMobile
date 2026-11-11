import 'package:flutter/material.dart';

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
Widget badge(BuildContext context, String text, {Color? color}) {
  final contrast = Theme.of(context).brightness == Brightness.dark;
  final c = contrast
      ? (text == 'Atrasada' ? const Color(0xffff8080) : const Color(0xffffff00))
      : color ?? const Color(0xff07535f);
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: contrast ? Colors.black : c.withOpacity(.1),
          border: Border.all(color: c),
          borderRadius: BorderRadius.circular(30)),
      child: Text(text,
          style:
              TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)));
}

Widget pageTitle(BuildContext context, String title, {Widget? action}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        ),
        if (action != null) action,
      ]),
    );
Widget errorBox(BuildContext context, String text) {
  final contrast = Theme.of(context).brightness == Brightness.dark;
  return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: contrast ? Colors.black : const Color(0xfffde7ea),
          border: Border(
              left: BorderSide(
                  color:
                      contrast ? const Color(0xffff8080) : Colors.red.shade900,
                  width: 4)),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(
              color: contrast ? const Color(0xffff8080) : Colors.red.shade900,
              fontWeight: FontWeight.w600)));
}

String dateText(dynamic value) {
  if (value == null) return '—';
  try {
    final d = DateTime.parse('$value');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return '—';
  }
}

Future<bool> confirmDialog(BuildContext context, String message) async =>
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
