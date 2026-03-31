# 🏋️ App de Controle de Volume de Treinamento

Sistema mobile (Flutter) + backend (Firebase) para controle de carga de musculação com progressão automática e periodização planejada.

---

## 📁 Estrutura do Repositório

```
App de calculo de carga/
├── firebase/                         ← Backend Firebase (100% implementado)
│   ├── firebase.json                 ← Configuração de emuladores e deploy
│   ├── firestore.rules               ← Regras de segurança do Firestore
│   ├── firestore.indexes.json        ← Índices compostos para queries
│   ├── storage.rules                 ← Regras do Firebase Storage (APK)
│   └── functions/                   ← Cloud Functions em TypeScript
│       └── src/
│           ├── index.ts             ← Entry point (4 Cloud Functions)
│           ├── volumeEngine.ts      ← Motor matemático puro
│           └── types.ts             ← Tipos TypeScript compartilhados
│
└── app/                              ← App Flutter (em desenvolvimento)
    └── lib/
        ├── main.dart                ← Entry point + inicialização Firebase
        ├── core/
        │   ├── router/app_router.dart   ← Roteamento com GoRouter
        │   └── services/auth_service.dart ← Serviço de autenticação
        ├── features/
        │   ├── auth/
        │   │   ├── login_screen.dart    ← Tela de login
        │   │   └── register_screen.dart ← Tela de cadastro
        │   └── dashboard/
        │       └── dashboard_screen.dart ← Dashboard (em branco por enquanto)
        └── shared/
            └── theme/app_theme.dart    ← Tema escuro global (Neo-Tactile)
```

---

## ⚙️ Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter / Dart (SDK ^3.11.4) |
| Backend | Firebase (Firestore, Auth, Functions, Storage) |
| Cloud Functions | TypeScript + Node.js ≥ 18 |
| Roteamento (Flutter) | `go_router ^17` |
| Estado (Flutter) | `provider ^6` |
| Fontes | `google_fonts` (Inter) |
| Gráficos (futuro) | `syncfusion_flutter_charts` |
| Animações | `flutter_animate` |

---

## 🔢 Regras Matemáticas do Volume Engine

O núcleo matemático fica em `volumeEngine.ts` (backend) e será espelhado no app Flutter:

```
volume = séries × repetições × carga
volume_alvo_semana = volume_anterior × (1 + progressão%)
carga = volume_alvo / (séries × reps)
carga arredondada para múltiplos de 2.5 kg
volume_novo >= volume_anterior  (exceto deload)
reps ∈ [repMin, repMax]  (padrão: 8–12)
```

### Funções implementadas em `volumeEngine.ts`

| Função | O que faz |
|--------|-----------|
| `calcVolume(series, reps, weight)` | Calcula o volume bruto |
| `calcWeekTarget(prevVolume, progressionPercent)` | Calcula o volume alvo da semana |
| `calcWeight(targetVolume, series, reps)` | Determina o peso necessário |
| `roundToNearest(value, multiple=2.5)` | Arredonda para múltiplo de 2.5 kg |
| `generateSuggestions(params)` | Gera todas as combinações séries/reps/peso válidas |

---

## ☁️ Cloud Functions (Backend)

Definidas em `firebase/functions/src/index.ts`:

### 1. `onWorkoutExerciseSave` — Trigger Firestore
- Dispara automaticamente ao salvar/editar um exercício num treino.
- Valida se o `volume` declarado bate com o calculado (`séries × reps × carga`). Se não bater, **corrige no servidor**.
- Agrega o volume total do exercício na semana e salva em `volumeHistory`.

### 2. `generateProgressionSuggestions` — Callable
- Chamada pelo app quando o usuário abre a tela de Sugestões.
- Busca o histórico da semana anterior, a configuração de progressão da semana atual e gera todas as combinações válidas de reps/peso.
- Persiste as sugestões em `suggestedProgressions` (limpa as antigas antes).
- Retorna: `{ prevVolume, targetVolume, progressionPercent, suggestions }`.

### 3. `calculatePeriodizationPlan` — Callable
- Recebe as configurações de todas as semanas de periodização.
- Retorna o plano completo de volume alvo semana a semana.
- Semanas de **deload** não propagam o volume (a semana seguinte usa o volume pré-deload).

### 4. `getApkVersion` — Callable
- Retorna os metadados da versão atual do APK (versão, URL de download, changelog).
- Lê do documento `config/apkVersion` no Firestore (somente admin pode escrever).

---

## 🗄️ Estrutura do Firestore

```
users/{uid}                         ← Perfil do usuário
  ├── exercises/{exId}              ← Exercícios cadastrados
  ├── workouts/{wId}                ← Sessões de treino
  │   └── exercises/{weId}         ← Exercícios executados na sessão
  ├── progressionWeeks/{pwId}       ← Configuração de periodização
  ├── volumeHistory/{vhId}          ← Histórico calculado (só Cloud Functions)
  └── suggestedProgressions/{spId} ← Sugestões geradas (só Cloud Functions)

config/apkVersion                   ← Metadados do APK (só admin)
```

### Tipos de dados (`types.ts`)

| Interface | Campos principais |
|-----------|------------------|
| `WorkoutExercise` | `exerciseId`, `series`, `reps`, `weight`, `volume` |
| `Exercise` | `name`, `seriesDefault`, `repMin`, `repMax` |
| `ProgressionWeek` | `weekNumber`, `progressionPercent`, `type` (base/progression/deload) |
| `VolumeHistoryEntry` | `exerciseId`, `weekNumber`, `totalVolume`, `updatedAt` |
| `Suggestion` | `series`, `reps`, `weight`, `volume`, `weekNumber` |
| `ApkVersionInfo` | `version`, `releaseDate`, `downloadUrl`, `changelog`, `minSupportedVersion` |

---

## 🔒 Segurança (Firestore Rules)

Regras completas em `firestore.rules`:

- **Isolamento total por usuário**: toda leitura/escrita é verificada por `request.auth.uid == uid`.
- **`volumeHistory`**: leitura permitida ao dono, **escrita bloqueada para o cliente** — somente via Admin SDK (Cloud Functions).
- **`suggestedProgressions`**: mesma lógica (só Cloud Functions escrevem).
- **`config/apkVersion`**: leitura pública para autenticados, escrita apenas via Admin SDK.
- **Validação de tipos e limites** embutida nas regras:
  - Strings com tamanho máximo
  - Números dentro de intervalos válidos (`weight: 0.5–1000`, `series: 1–20`, etc.)
  - `repMin <= repMax` verificado na regra de criação
  - Semanas de progressão: tipo deve ser `'base' | 'progression' | 'deload'`
- **Delete de usuário bloqueado** (`allow delete: if false`) — apenas soft-delete via Functions.
- **Catch-all**: `match /{document=**} { allow read, write: if false; }` — tudo não mapeado é negado.

---

## 📱 App Flutter — O que foi implementado

### `main.dart`
- Inicializa o Firebase com as opções geradas automaticamente (`firebase_options.dart`).
- Conecta aos **emuladores locais** (Firestore em `localhost:8080`, Auth em `localhost:9099`) para desenvolvimento.
- Injeta `AuthService` via `Provider` e configura o roteador.
- Aplica o tema escuro globalmente.

### `AppTheme` — Tema Neo-Tactile (Dark)
Paleta de cores definida em `app_theme.dart`:

| Token | Cor (Hex) | Uso |
|-------|-----------|-----|
| `background` | `#0A0A0F` | Fundo geral |
| `surface` | `#181822` | Cards e superfícies |
| `surfaceHighlight` | `#232332` | Inputs |
| `accent` | `#3B82FF` | Azul primário (botões, foco) |
| `success` | `#22C55E` | Verde (progressão positiva) |
| `danger` | `#EF4444` | Vermelho (deload, erros) |
| `textPrimary` | `#F3F4F6` | Texto principal |
| `textSecondary` | `#9CA3AF` | Texto auxiliar |

- Fonte: **Inter** via Google Fonts.
- Cards com borda sutil `rgba(255,255,255,0.12)`, `borderRadius: 16`.
- Botões elevados com sombra colorida (`accent.withOpacity(0.5)`).
- Inputs com fundo `surfaceHighlight` e borda de foco azul de 2px.

### `AuthService`
- Wrapper sobre `FirebaseAuth` exposto como `ChangeNotifier` (para o `Provider`).
- **Login**: `signInWithEmailAndPassword`.
- **Cadastro**: cria conta no Auth + documento de perfil em `users/{uid}` no Firestore.
- **Logout**: `signOut`.
- **Tratamento de erros em português**: mensagens amigáveis para `user-not-found`, `wrong-password`, `email-already-in-use`, `weak-password`, `invalid-email`.

### `AppRouter` (GoRouter)
- Roteamento declarativo com redirecionamento automático baseado no estado de autenticação.
- Se **não autenticado** → redireciona para `/login`.
- Se **autenticado** tentando acessar `/login` ou `/register` → redireciona para `/dashboard`.
- Rotas: `/login`, `/register`, `/dashboard`.

### `LoginScreen`
- Formulário com e-mail e senha.
- Loading state no botão enquanto autentica.
- Exibe erro formatado em caixa vermelha se falhar.
- Link para `/register`.

### `RegisterScreen`
- Formulário com nome, e-mail, senha e confirmação de senha.
- Validações de campo antes de chamar o `AuthService`.
- Cria conta e perfil no Firestore automaticamente.

---

## 🔑 Índices do Firestore (`firestore.indexes.json`)

| Coleção | Campos indexados |
|---------|-----------------|
| `workouts` | `weekNumber ASC` + `date DESC` |
| `volumeHistory` | `exerciseId ASC` + `weekNumber ASC` |
| `suggestedProgressions` | `exerciseId ASC` + `weekNumber ASC` + `volume ASC` |

---

## 🚀 Como Rodar Localmente

### Pré-requisitos
- Flutter SDK
- Node.js ≥ 18
- Firebase CLI: `npm install -g firebase-tools`

### 1. Backend (Firebase Emulators)

```bash
cd firebase
firebase login
firebase use --add        # Selecione seu projeto Firebase
cd functions
npm install
cd ..
firebase emulators:start  # http://localhost:4000
```

### 2. App Flutter

```bash
cd app
flutter pub get
flutter run
```

> O app já está configurado para apontar para os emuladores locais automaticamente.

### 3. Rodar Testes das Cloud Functions

```bash
cd firebase/functions
npm test
```

### 4. Deploy para Produção

```bash
cd firebase
firebase deploy            # Deploy de rules, indexes e functions
```

---

## ✅ Progresso do Projeto

| Componente | Status |
|-----------|--------|
| Estrutura Firebase (rules, indexes, functions) | ✅ Completo |
| Cloud Functions (4 functions) | ✅ Completo |
| Motor matemático (`volumeEngine.ts`) | ✅ Completo |
| Tipos TypeScript (`types.ts`) | ✅ Completo |
| Tema escuro Flutter (`AppTheme`) | ✅ Completo |
| Autenticação Flutter (`AuthService`) | ✅ Completo |
| Roteamento Flutter (`AppRouter` + GoRouter) | ✅ Completo |
| Tela de Login | ✅ Completo |
| Tela de Cadastro | ✅ Completo |
| Dashboard (tela principal) | 🔄 Em desenvolvimento |
| Tela de Exercícios | ⏳ Pendente |
| Tela de Treino | ⏳ Pendente |
| Tela de Sugestões de Progressão | ⏳ Pendente |
| Tela de Periodização | ⏳ Pendente |
| Gráficos de volume (syncfusion) | ⏳ Pendente |
| Website Next.js | ⏳ Pendente |
| Sistema de download do APK | ⏳ Pendente |
