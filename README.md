# PIMMobile

Aplicativo independente em Flutter e Dart para uso do PIM IV em dispositivos móveis e navegador. O PIMMobile apresenta fluxos de autenticação, tarefas, equipes e administração usando uma interface responsiva, e acessa os dados e regras disponíveis no PIMBackend por uma API REST.

O aplicativo é um cliente separado do PIMFrontend Web: não depende dos arquivos nem da execução do frontend web. Ambos podem compartilhar o PIMBackend, que centraliza os dados e a autenticação. O acesso web pelo Chrome é útil para desenvolvimento e validação responsiva; não substitui testes em celular.

## Tecnologias

As dependências declaradas em `pubspec.yaml` incluem:

| Tecnologia | Uso no projeto |
| --- | --- |
| Flutter e Dart | Interface e lógica do aplicativo; SDK Dart `>=3.3.0 <4.0.0`. |
| Dio | Requisições HTTP e interceptação de autenticação/erros. |
| flutter_riverpod | Estado de sessão, configuração e dependências. |
| go_router | Rotas e redirecionamentos por sessão e perfil. |
| flutter_secure_storage | Armazenamento local dos tokens e dos dados de usuário. |
| shared_preferences | Preferências de acessibilidade, como contraste e escala de texto. |
| flutter_test | Infraestrutura de testes declarada como dependência de desenvolvimento. |
| flutter_lints | Regras de análise estática declaradas como dependência de desenvolvimento. |

## Estrutura do projeto

- `lib/`: código Dart do aplicativo.
- `lib/core/`: URL da API e cliente Dio, incluindo autenticação e erros.
- `lib/features/`: telas e componentes dos fluxos de login, painel, tarefas e gestão.
- `lib/models/`: modelo de sessão do usuário.
- `lib/services/`: operações HTTP usadas pelas telas.
- `lib/providers/`: estado e provedores Riverpod.
- `lib/routes/`: constantes de caminhos de navegação. A configuração efetiva do GoRouter também está em `lib/main.dart`.
- `lib/repositories/` e `lib/dtos/`: acesso a tarefas e representação de dados para operações de tarefa.
- `test/`: testes Flutter existentes.
- `android/`, `ios/` e `web/`: arquivos de plataforma Flutter presentes no repositório.
- `docs/`: não existe nesta cópia do repositório; portanto não há documentos complementares a vincular.

## Pré-requisitos no Ubuntu

- Ubuntu com ferramentas básicas de desenvolvimento, Git e acesso à internet para obter o Flutter e pacotes Dart.
- Flutter SDK em uma versão compatível com o constraint do projeto (`>=3.3.0 <4.0.0` de Dart). Instale o Flutter seguindo o [guia oficial para Linux](https://docs.flutter.dev/get-started/install/linux) e configure o diretório `bin` do SDK no `PATH`.
- Para Android: Android Studio/Android SDK e um emulador configurado, ou um dispositivo Android com depuração USB habilitada. A configuração nativa Android já está versionada.
- Para iOS, é necessário macOS com Xcode; não é possível compilar ou executar o destino iOS nativamente no Ubuntu.
- Para Chrome/Web: navegador Chrome ou Chromium instalado e reconhecido pelo Flutter.
- Para chamadas à API, PIMBackend disponível e acessível na URL configurada.

Confira a instalação e os dispositivos/navegadores reconhecidos:

```sh
flutter --version
dart --version
flutter doctor
flutter devices
```

Flutter Web atualmente é habilitado por padrão nas versões recentes do Flutter. Se a instalação indicar que é necessário ativar suporte web, use:

```sh
flutter config --enable-web
```

## Instalação

Na raiz do repositório:

```sh
flutter pub get
```

Os diretórios `android/`, `ios/` e `web/` já estão presentes e configurados; não é necessário regenerá-los com `flutter create`.

## Configuração da API

`lib/core/config.dart` lê a constante de compilação `PIM_API_URL` por `String.fromEnvironment`. O valor padrão é `http://localhost:5000`. Informe outro endereço com `--dart-define=PIM_API_URL=...`. O cliente acrescenta `/api/v1` à URL base, removendo uma barra final se houver.

| Ambiente | Valor base sugerido para `PIM_API_URL` | Observação |
| --- | --- | --- |
| Flutter Web no mesmo computador do Backend | `http://localhost:5000` | O Backend recebe na porta 5000; o comando abaixo serve o aplicativo na porta 5001. |
| Emulador Android | `http://10.0.2.2:5000` | `10.0.2.2` é o endereço especial usado pelo emulador Android para alcançar o host. |
| Celular físico | `http://IP_LOCAL_DO_COMPUTADOR:5000` | Use o IP do computador na rede local; celular e computador precisam estar na mesma rede e o firewall deve permitir o acesso. |
| FlutLab | URL pública HTTPS do Backend | O ambiente remoto normalmente não consegue alcançar `localhost` nem IPs privados da rede local. |

Durante testes remotos, um túnel como [ngrok](https://ngrok.com/) ou [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) pode expor temporariamente o Backend por HTTPS. Proteja a URL e encerre o túnel quando não precisar dele.

## Executar pelo Chrome

Com o Backend acessível em `http://localhost:5000`, execute:

```sh
flutter run -d chrome --web-port 5001 --dart-define=PIM_API_URL=http://localhost:5000
```

O Flutter abrirá o aplicativo no Chrome, servido na porta 5001. Se o navegador não abrir automaticamente, use o endereço local informado no terminal, normalmente `http://localhost:5001`.

- Abra o Chrome DevTools com `F12` ou `Ctrl + Shift + I` para inspecionar console, rede e erros HTTP.
- Use `Ctrl + Shift + M` para alternar a simulação de dispositivos móveis no DevTools.
- Durante uma sessão iniciada com `flutter run`, pressione `r` no terminal para Hot Reload e `R` para Hot Restart. Hot Reload preserva o estado possível da aplicação; Hot Restart reinicia o estado Dart.
- Pressione `q` no terminal para encerrar a execução.

A simulação responsiva do Chrome não reproduz integralmente o comportamento de um dispositivo físico nem substitui testes nele.

## Executar no Android

Confira os dispositivos disponíveis com `flutter devices`. Para emulador Android iniciado:

```sh
flutter run -d <ID_DO_EMULADOR> --dart-define=PIM_API_URL=http://10.0.2.2:5000
```

Para celular conectado e reconhecido pelo Flutter:

```sh
flutter run -d <ID_DO_DISPOSITIVO> --dart-define=PIM_API_URL=http://IP_LOCAL_DO_COMPUTADOR:5000
```

Substitua o identificador pelo valor listado por `flutter devices` e o IP pelo endereço local do computador que executa o Backend. No emulador, `localhost` aponta para o próprio Android virtual; `10.0.2.2` aponta para o computador host. No celular físico, use o IP local do host, e não `localhost`.

## Executar no FlutLab

Os nomes e opções da interface do FlutLab podem variar; use os recursos disponíveis na versão atual da plataforma para configurar argumentos de compilação.

1. Abra o FlutLab e importe/crie um projeto a partir deste repositório, incluindo `pubspec.yaml` e as pastas de código e plataforma necessárias.
2. Aguarde a resolução das dependências do `pubspec.yaml`; se a plataforma oferecer terminal, execute `flutter pub get`.
3. Disponibilize o PIMBackend por uma URL HTTPS pública. Para desenvolvimento, um túnel HTTPS como ngrok ou Cloudflare Tunnel pode servir para isso.
4. Configure a variável de compilação `PIM_API_URL` com essa URL pública, usando o mecanismo de argumentos `--dart-define` se disponível na configuração de build/execução do projeto: `PIM_API_URL=https://sua-url-publica`. Não use localhost ou IP privado para o Backend acessado pelo ambiente remoto.
5. Execute o aplicativo na plataforma e valide login, listagem/detalhe de tarefas e operações disponíveis para o perfil utilizado.

A disponibilidade de um campo específico para `--dart-define` na interface do FlutLab não foi confirmada neste repositório. Se a plataforma não permitir informar variáveis de compilação, será necessário usar um recurso equivalente oferecido por ela; o código atualmente só lê a configuração `PIM_API_URL`.

## Integração com o PIMBackend

O `ApiClient` usa Dio e constrói a base da API como `<PIM_API_URL>/api/v1`. O serviço envia e recebe dados JSON pelos métodos HTTP GET, POST, PUT, PATCH e DELETE, conforme a operação.

No login (`POST /auth/login`), a aplicação recebe e persiste `accessToken`, `refreshToken` e, quando presente, os dados do usuário. O cliente adiciona `Authorization: Bearer <accessToken>` às requisições. Os tokens são guardados pelo `flutter_secure_storage`; preferências de acessibilidade ficam em `shared_preferences`.

Quando uma resposta é 401 e existe refresh token, o cliente tenta `POST /auth/refresh` com `refreshToken`, salva os tokens retornados e repete uma vez a requisição original. Se a renovação falhar, limpa os tokens e sinaliza que a sessão expirou. O logout envia `POST /auth/logout` com o refresh token e limpa o armazenamento local.

Erros da API são apresentados usando os campos `errors`, `error` ou `detail` quando disponíveis; erros de comunicação também são convertidos em mensagens para as telas.

No Flutter Web, o navegador aplica a política CORS. Se a chamada falhar por CORS, o PIMBackend precisa autorizar a origem usada pelo aplicativo (por exemplo, `http://localhost:5001`) e os métodos/cabeçalhos necessários. CORS é uma restrição do navegador; mudar o cliente Flutter não substitui a configuração de origens no Backend. Em contextos que exigem HTTPS, uma API servida apenas por HTTP pode ser bloqueada como conteúdo misto.

## Funcionalidades implementadas

- Login, restauração de sessão salva e logout; permissões de navegação por perfil (`Admin`, `Gestor` e `Colaborador`).
- Painel para perfis de gestão, com resumo de tarefas por colaborador e lista de tarefas atrasadas.
- Listagem paginada de tarefas, busca, filtros por status/prioridade e, para gestão, por colaborador.
- Visualização de detalhes, alteração de status, comentários e histórico de status; reatribuição de colaborador para perfis de gestão.
- Criação, edição e exclusão de tarefas por perfis de gestão.
- Consulta e manutenção de colaboradores e equipes por perfis de gestão, incluindo adicionar/remover membros de equipes.
- Administração de usuários por perfil Admin, incluindo criação/edição, ativação/inativação e redefinição de senha.
- Preferência de alto contraste; ajuste de escala de texto em telas largas.

## Testes e validação

Os comandos abaixo estão documentados para uso local; não indicam que tenham sido executados nesta revisão:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port 5001 --dart-define=PIM_API_URL=http://localhost:5000
```

Para validar a comunicação com a API, inicie o Backend e confira se a URL base está correta. No Chrome, verifique no DevTools (abas Console e Network) se a requisição alcança `http://localhost:5000/api/v1`, se o preflight/CORS é aceito e se a resposta de login e das operações retorna como esperado. Em Android, confirme que a URL usa `10.0.2.2` no emulador ou o IP local do host no celular.

## Problemas comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| `flutter` ou `dart` não encontrado | SDK ausente ou `bin` fora do `PATH`. | Instale/configure o Flutter SDK e abra um novo terminal; confira `flutter doctor`. |
| Dependências não resolvidas | Sem rede, versão incompatível ou resolução incompleta. | Confira o constraint Dart em `pubspec.yaml`, a conexão e execute `flutter pub get`. |
| Chrome não encontrado | Chrome/Chromium não instalado ou não reconhecido pelo Flutter. | Instale um navegador compatível e confira `flutter devices`/`flutter doctor`. |
| Erro ao compilar para Web | Dependência/plugin incompatível ou erro de compilação. | Leia a primeira mensagem de erro no terminal, confirme SDK/dependências e verifique se as dependências usadas suportam Web. |
| `XMLHttpRequest error` no Chrome | Falha de rede, CORS, URL incorreta, HTTPS/HTTP incompatível ou Backend inacessível. | Inspecione Network/Console no DevTools e valide URL, Backend e CORS. |
| Erro de CORS | A origem do app web não foi autorizada pelo Backend. | Configure no Backend a origem exata do app (por exemplo `http://localhost:5001`), além dos métodos e cabeçalhos usados. |
| API não responde ou URL incorreta | `PIM_API_URL` aponta para host/porta errados ou o processo não está acessível. | Confirme a URL base e a conectividade; lembre-se de que o cliente acrescenta `/api/v1`. |
| Backend indisponível | Serviço parado, firewall ou rede bloqueando a porta. | Inicie o Backend, libere a porta necessária e teste a conectividade a partir do dispositivo/ambiente que executa o app. |
| HTTP 401 | Credenciais inválidas, token expirado ou falha na renovação. | Faça login novamente e confira configuração/contrato de autenticação e refresh no Backend. |
| HTTP 404 | Caminho inexistente, prefixo/base incorretos ou recurso não encontrado. | Confira a rota no Backend e o prefixo `/api/v1`; valide também o identificador enviado. |
| Token não persiste ou erro de armazenamento | Restrição/permissão do armazenamento seguro no destino ou falha do plugin. | Confira logs do dispositivo e suporte/configuração do plugin para a plataforma em uso; faça novo login após corrigir. |
| API local não acessível pelo FlutLab | Ambiente remoto sem rota para localhost ou rede privada do computador. | Use uma URL pública HTTPS alcançável, por exemplo por túnel temporário. |
| Requisição HTTP bloqueada | O contexto exige HTTPS e bloqueia conteúdo HTTP inseguro. | Disponibilize a API por HTTPS e configure essa URL em `PIM_API_URL`. |

## Documentação complementar

Não há pasta `docs/` neste repositório no momento. O contrato de integração deve ser conferido no PIMBackend; não foi possível confirmar neste repositório um documento complementar com os endpoints.
