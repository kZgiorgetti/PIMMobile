# Levantamento e checklist de migração

## Inventário observado no PIMFrontend web

- Login com e-mail/senha, JWT, refresh ao receber 401, logout e expiração de sessão.
- Navegação condicionada aos perfis `Admin`, `Gestor` e `Colaborador`; preferências de alto contraste e fonte.
- Painel (Admin/Gestor): contagem por status, progresso por colaborador, tarefas atrasadas.
- Tarefas: busca, status, prioridade, filtro por colaborador para gestores, paginação de 10, criação, edição, exclusão e conclusão.
- Detalhe de tarefa: descrição, prazo, prioridade, status, reatribuição por gestor, histórico e comentários.
- Colaboradores (Admin/Gestor): lista, criar, editar e remover/inativar.
- Equipes (Admin/Gestor): lista, criar, editar, excluir, adicionar/remover membro.
- Usuários (Admin): lista, criar, editar perfil/dados, redefinir senha, ativar/inativar; não oferecer alteração de situação do próprio usuário.

## Contratos REST extraídos dos serviços web

- `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`.
- `GET /relatorios/resumo-por-colaborador`, `GET /relatorios/atrasadas`.
- `GET /tarefas?busca&status&prioridade&colaboradorId&page&pageSize`; `GET/POST /tarefas`, `GET/PUT/DELETE /tarefas/{id}`, `PATCH /tarefas/{id}/status`, `POST /tarefas/{id}/concluir`, `POST /tarefas/{id}/reatribuir`, `GET /tarefas/{id}/historico`, `GET/POST /tarefas/{id}/comentarios`.
- `GET /colaboradores?apenasAtivos`, `POST /colaboradores`, `PUT/DELETE /colaboradores/{id}`.
- `GET/POST /equipes`, `PUT/DELETE /equipes/{id}`, `POST/DELETE /equipes/{id}/colaboradores/{colaboradorId}`.
- `GET/POST /usuarios`, `PUT /usuarios/{id}`, `POST /usuarios/{id}/redefinir-senha`, `POST /usuarios/{id}/ativar`, `POST /usuarios/{id}/inativar`.

## Estado de migração

- [x] Tema e identidade: cores primárias `#07535f`, fundo `#f5fbfc`, superfície `#e8f6f8`, texto `#17343a`, borda `#c5dfe3`, alertas equivalentes.
- [x] Autenticação, armazenamento seguro, refresh, logout e rotas com controle de perfil.
- [x] Painel, listagem e detalhe de tarefas, filtros, paginação, comentários/histórico e ações comuns.
- [x] CRUD básico de colaboradores, equipes e usuários, senha e situação de usuário, associação de membro.
- [x] Adicionar e remover membros da equipe.
- [x] Preferências persistidas de alto contraste e escala de fonte.
- [ ] Validação executável com Flutter e comparação visual em aparelho/emulador.
- [ ] Gerar e validar os projetos nativos Android/iOS com `flutter create`.

As pendências estão expostas aqui porque o SDK não está disponível neste ambiente e a migração dos cadastros não está completa em todos os fluxos. A API de remoção de membro existe e foi identificada, mas falta conectá-la a uma ação visível.
