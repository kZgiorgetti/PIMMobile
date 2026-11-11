import '../dtos/task_dto.dart';
import '../services/pim_service.dart';

class TaskRepository {
  const TaskRepository(this.service);
  final PimService service;
  Future<Map<String,dynamic>> list({String search='',String status='',String priority='',int? collaboratorId,int page=1,int pageSize=10}) async => Map<String,dynamic>.from(await service.get('/tarefas',query:{'busca':search,'status':status,'prioridade':priority,'colaboradorId':collaboratorId,'page':page,'pageSize':pageSize}) as Map);
  Future<void> create(TaskDto task) async { await service.post('/tarefas',task.toJson()); }
  Future<void> update(int id,TaskDto task) async { await service.put('/tarefas/$id',task.toJson()); }
  Future<void> delete(int id) async { await service.delete('/tarefas/$id'); }
}
