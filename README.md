# BuildFit

Aplicativo Flutter para prescricao e acompanhamento de treinos, com landing page Next.js e Supabase como unica camada de autenticacao, banco e persistencia.

## Arquitetura

- `app_flutter/`: aplicativo Flutter Android, iOS e Web.
- `app/`: landing page Next.js.
- `public/treino/`: build Web do Flutter servido em `/treino/`.
- `public/download/apk.apk`: APK disponibilizado na landing page.
- `supabase_schema.sql`: schema base do banco.
- `fix_supabase_auth.sql`: sincronizacao de perfil com Supabase Auth.
- `fix_rls_policies.sql`: politicas RLS.

O Flutter usa Supabase Auth e PostgREST diretamente por meio de `SupabaseService`. Nao existe backend intermediario, Firebase, Railway ou armazenamento externo de imagens.

## Desenvolvimento

Pre-requisitos:

- Flutter SDK compativel com o `pubspec.yaml`.
- Node.js 20 ou superior.
- Projeto Supabase configurado com as tabelas e politicas SQL deste repositorio.

Landing page:

```bash
npm ci
npm run build
npm run start
```

Aplicativo Flutter:

```bash
cd app_flutter
flutter pub get
flutter run
```

## Builds Seguros

O APK usa memoria limitada pelo Gradle em `app_flutter/android/gradle.properties` e nao mantém daemon persistente.

```bash
cd app_flutter
flutter pub get
flutter build apk --release --no-tree-shake-icons
flutter build web --release --no-tree-shake-icons
```

O build web deve ser copiado para `public/treino/` antes do deploy caso o app Flutter tenha sido alterado.

## Deploy

A landing page e o Flutter Web sao publicados pelo Vercel:

```bash
npm run build
vercel --prod --yes
```

O deploy nao executa Gradle nem recompila o APK. O APK publicado deve ser gerado separadamente e copiado para `public/download/apk.apk`.

## Fluxo de dados

`anamnese -> perfil -> motor de prescricao -> treino -> Supabase Auth/PostgREST -> tela`

As politicas RLS devem ser aplicadas no Supabase antes de testar persistencia em producao.
