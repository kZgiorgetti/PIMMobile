# PIMMobile

Aplicativo independente desenvolvido em Flutter e Dart para acessar os fluxos do PIM por dispositivos móveis e navegador. O app se comunica com a API REST do PIMBackend; não depende da execução do PIMFrontend.

## Objetivo e funcionalidades

O aplicativo oferece autenticação e navegação conforme o perfil do usuário. Os fluxos implementados incluem painel de gestão, consulta e manutenção de tarefas, comentários e histórico de status, gestão de colaboradores e equipes e administração de usuários. As ações disponíveis variam conforme o perfil e as permissões aplicadas pela API.

## Tecnologias utilizadas

- Flutter e Dart (constraint atual: Dart `>=3.3.0 <4.0.0`).
- Dio para chamadas HTTP; `flutter_riverpod` para estado e injeção de dependências.
- `go_router` para navegação e redirecionamento por sessão/perfil.
- `flutter_secure_storage` para tokens e dados do usuário; `shared_preferences` para preferências de acessibilidade.
- `flutter_test` e `flutter_lints` para testes e análise.

As dependências e versões permitidas estão em [pubspec.yaml](pubspec.yaml); [pubspec.lock](pubspec.lock) registra a resolução usada pelo projeto.

## Estrutura de pastas

- `lib/core/`: configuração da API e cliente HTTP.
- `lib/dtos/`, `lib/models/` e `lib/repositories/`: representação e acesso a dados.
- `lib/features/`: telas de login, painel, tarefas e gestão.
- `lib/providers/`: estado da sessão.
- `lib/routes/`: caminhos de navegação compartilhados; o GoRouter é configurado em `lib/main.dart`.
- `lib/services/`: operações da API usadas pelas telas.
- `android/`, `ios/` e `web/`: projetos e arquivos de plataforma já existentes.
- `test/`: testes automatizados.
- `assets/`: não há diretório de assets separado nesta versão; ícones e recursos de plataforma ficam nos diretórios de plataforma.

## Pré-requisitos

- Git e Flutter SDK instalado. O constraint de Dart é `>=3.3.0 <4.0.0`; use uma versão do Flutter que inclua Dart compatível.
- Para Web: Chrome instalado e reconhecido pelo Flutter.
- Para Android: Android SDK e Android Studio (ou ferramentas equivalentes), além de emulador configurado ou celular com depuração USB habilitada.
- Para iOS: macOS e Xcode. A pasta `ios/` está no repositório; compilação e execução iOS requerem essas ferramentas Apple.
- PIMBackend em execução e acessível pelo ambiente do aplicativo.

Instale o Flutter seguindo o [guia oficial de instalação](https://docs.flutter.dev/get-started/install) para seu sistema operacional e configure o diretório `bin` do SDK no `PATH`. Depois confira:

```sh
flutter --version
dart --version
flutter doctor
flutter devices
```

## Instalação das dependências

Na raiz do repositório:

```sh
flutter pub get
```

Os diretórios `android/`, `ios/` e `web/` já existem e estão versionados; não é necessário recriá-los.

## Configuração da URL da API

`lib/core/config.dart` lê `PIM_API_URL` como variável de compilação por `String.fromEnvironment`. Sem definição, o valor padrão é `http://localhost:5000`. O cliente remove uma barra final e acrescenta `/api/v1`, formando a base usada nas chamadas.

| Ambiente | Valor de `PIM_API_URL` |
| --- | --- |
| Chrome no mesmo computador da API | `http://localhost:5000` |
| Emulador Android | `http://10.0.2.2:5000` |
| Celular físico | `http://IP_DA_MAQUINA:5000` |
| FlutLab | URL pública HTTPS da API |

Passe o valor no comando com `--dart-define=PIM_API_URL=...`. O FlutLab executa o projeto em ambiente remoto e não consegue acessar o `localhost` do computador do usuário. Disponibilize a API em uma URL pública HTTPS, por túnel ou hospedagem acessível externamente, e use essa URL na configuração de build/execução oferecida pela plataforma. Não inclua credenciais em argumentos ou no repositório.

## Execução no Chrome

Com a API disponível localmente na porta 5000:

```sh
flutter run -d chrome --web-port 5001 --dart-define=PIM_API_URL=http://localhost:5000
```

O navegador acessa o app local na porta 5001 e as chamadas da API usam `/api/v1`. No Flutter Web, o navegador aplica CORS; configure o Backend para autorizar a origem do app (por exemplo, `http://localhost:5001`) e os métodos/cabeçalhos necessários. CORS é uma política de navegador e não opera da mesma maneira nos apps nativos Android e iOS. HTTP/HTTPS incompatíveis também podem causar bloqueio de conteúdo misto no navegador.

## Execução no emulador Android

Inicie um emulador reconhecido por `flutter devices` e rode:

```sh
flutter run --dart-define=PIM_API_URL=http://10.0.2.2:5000
```

`10.0.2.2` é o endereço especial pelo qual o emulador Android acessa o computador host. Em `localhost`, o emulador tentaria acessar a si próprio.

## Execução em dispositivo físico

Conecte o aparelho com depuração USB habilitada, confirme que aparece em `flutter devices` e substitua o IP pelo endereço local do computador que hospeda a API:

```sh
flutter run --dart-define=PIM_API_URL=http://IP_DA_MAQUINA:5000
```

O computador e o dispositivo precisam estar na mesma rede local. A API deve aceitar conexões externas nessa rede (por exemplo, escutar na interface de rede apropriada), e o firewall deve permitir a porta. `localhost` no celular aponta para o próprio celular.

## Execução no FlutLab

Importe o repositório no FlutLab e aguarde a resolução do `pubspec.yaml` (ou execute `flutter pub get` se houver terminal). Configure `PIM_API_URL` no mecanismo de argumentos/compilação disponível na plataforma, com a URL pública HTTPS do Backend. Uma API em `localhost` ou em IP privado do computador não é acessível diretamente pelo ambiente remoto. A interface e suporte exatos a argumentos de compilação dependem da versão atual do FlutLab.

## Integração com o Backend

O PIMMobile é independente e consome a mesma API REST usada pelo PIMFrontend. A base é `<PIM_API_URL>/api/v1`; o contrato efetivo (rotas, campos, permissões e respostas) deve ser consultado no Backend. O serviço mobile chama, entre outros, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/tarefas`, `/colaboradores`, `/equipes`, `/usuarios` e `/relatorios`.

No login, o cliente recebe `accessToken`, `refreshToken` e dados do usuário, envia o access token como `Authorization: Bearer ...`, tenta renovar a sessão após resposta 401 e limpa os dados locais se a renovação falhar. Tokens e usuário são gravados por `flutter_secure_storage`; preferências de contraste e escala de texto ficam em `shared_preferences`. A disponibilidade e o comportamento desses plugins variam por plataforma, em especial no Web; valide o armazenamento no destino desejado.

- [PIMBackend](https://github.com/kZgiorgetti/PIMBackend)
- [PIMFrontend](https://github.com/kZgiorgetti/PIMFrontend)

## Testes e análise estática

Execute na raiz do projeto:

```sh
flutter analyze
flutter test
```

Os testes em `test/` cobrem rótulos de status/prioridade e há também um teste widget legado que deve ser conferido contra o app atual. Os comandos acima são os meios de validação; consulte seus resultados no ambiente em que forem executados.

## Geração de builds

Com Flutter e toolchains de destino instalados, os comandos compatíveis com a estrutura Flutter presente são:

```sh
flutter build web --dart-define=PIM_API_URL=https://api.exemplo.com
flutter build apk --dart-define=PIM_API_URL=https://api.exemplo.com
```

Use uma URL alcançável pelo destino e adequada ao ambiente de distribuição. Build iOS requer macOS/Xcode. A presença do projeto de plataforma torna esses alvos disponíveis, mas não garante que compilação, plugins ou configuração do ambiente estejam corretos sem executar o build.

## Problemas comuns e soluções

| Sintoma | Verificação/solução |
| --- | --- |
| `flutter` ou `dart` não encontrado | Instale o Flutter SDK, inclua `bin` no `PATH` e confira `flutter doctor`. |
| Dependências não resolvem | Confirme rede e versão Dart compatível; execute `flutter pub get` e leia o primeiro erro de resolução. |
| Chrome ou emulador não aparece | Instale/configure o destino e confira `flutter devices` e `flutter doctor`. |
| App não alcança a API no Android | Use `10.0.2.2` no emulador ou o IP local do computador no celular; confirme porta, firewall e disponibilidade da API. |
| `XMLHttpRequest error` ou CORS no Chrome | Confira URL, disponibilidade, Console/Network do DevTools e autorização CORS da origem web no Backend. |
| FlutLab não acessa a API local | Configure URL pública HTTPS; `localhost` e IP privado não são acessíveis diretamente pelo ambiente remoto. |
| HTTP bloqueado em contexto HTTPS | Publique a API via HTTPS e atualize `PIM_API_URL`. |
| Resposta 401 | Confira credenciais, validade do refresh token e contrato de autenticação do Backend; tente entrar novamente. |
| Rota retorna 404 | Confira prefixo `/api/v1`, caminho e identificador conforme o contrato atual do Backend. |
| Falha de build ou plugin | Leia o primeiro erro do terminal e confirme versões/toolchains da plataforma; a pasta de plataforma existente não dispensa essa configuração. |
