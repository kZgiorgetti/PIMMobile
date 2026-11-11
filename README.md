# PIMFrontend Mobile

Aplicativo independente em Flutter/Dart para substituir, no uso móvel, as telas existentes do PIMFrontend web. O frontend web e seus arquivos não são necessários para executar o aplicativo.

## Requisitos

- Flutter SDK compatível com Dart `>=3.3.0 <4.0.0`.
- Backend PIMBackend em execução na porta 5000 ou URL configurada.

## Configurar e executar

```sh
flutter pub get
flutter run --dart-define=PIM_API_URL=http://10.0.2.2:5000
```

`10.0.2.2` aponta para o host a partir do emulador Android. Para dispositivo físico, use o endereço IP da máquina na rede local. O valor padrão está em `lib/core/config.dart`; ele pode ser substituído com `PIM_API_URL` sem alterar as telas.

Para gerar os invólucros nativos no ambiente com Flutter instalado, execute `flutter create --platforms=android,ios .` a partir desta pasta. O ambiente usado para preparar os fontes não contém Flutter/Dart, então não foi possível gerar os diretórios de plataforma ou executar `flutter analyze`, `flutter test` e builds. Nenhuma credencial está incluída; JWTs são armazenados com `flutter_secure_storage`.

## Estrutura

- `lib/core`: URL, cliente Dio, tema e tratamento de erro.
- `lib/models`: sessão autenticada.
- `lib/services`: operações REST do PIMBackend.
- `lib/providers`: estado de sessão Riverpod.
- `lib/routes` e `lib/main.dart`: navegação GoRouter e shell responsivo.
- `lib/features`: login, painel, tarefas, detalhe, colaboradores, equipes e usuários.
- `test`: destino dos testes Flutter.
- `assets`: destino de ativos próprios da aplicação.

## Contratos usados

Todos os caminhos usam o prefixo `/api/v1`. A lista de operações observada no frontend web está em `docs/migracao.md`.
