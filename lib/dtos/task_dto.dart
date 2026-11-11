class TaskDto {
  const TaskDto({required this.title, this.description = '', this.priority = 'Media', this.dueDate, this.collaboratorId, this.teamId});
  final String title;
  final String description;
  final String priority;
  final DateTime? dueDate;
  final int? collaboratorId;
  final int? teamId;
  Map<String,dynamic> toJson() => {
    'titulo': title,
    'descricao': description,
    'prioridade': priority,
    'dataPrazo': dueDate == null ? null : '${dueDate!.toIso8601String().substring(0,10)}T23:59:00Z',
    'colaboradorId': collaboratorId,
    'equipeId': teamId,
  };
}
