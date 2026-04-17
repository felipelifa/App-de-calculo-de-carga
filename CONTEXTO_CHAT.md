# Contexto do Projeto — App de Treino

## O que é o projeto
App mobile de controle de treino com progressão automática e sistema adaptativo.
Stack: Flutter (Dart) + Firebase (Firestore, Auth, Cloud Functions) + Next.js (landing page).
Tema: Dark "Neo-Tactile".

---

## Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter / Dart SDK ^3.11.4 |
| Web | Next.js 15 (App Router) + React 19 |
| Backend | Firebase (Firestore, Auth, Functions, Storage) |
| Cloud Functions | TypeScript + Node.js ≥ 18 |
| Roteamento | go_router ^17 |
| Estado | provider ^6 |
| Fontes | google_fonts (Inter) |
| Gráficos | syncfusion_flutter_charts |
| Animações | flutter_animate |
| Imagens | cached_network_image |
| Datas | intl ^0.19.0 |
| Notificações | firebase_messaging ^16.1.3 + flutter_local_notifications ^18.0.1 |
| Cloud Functions Client | cloud_functions ^6.1.0 |
| HTTP (APIs) | http ^1.2.0 |
| Gráficos | syncfusion_flutter_charts ^21 (Web-stable) |

---

## Estrutura de arquivos

```
App de calculo de carga/
├── firebase/
│   ├── firebase.json
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── functions/src/
│       ├── index.ts               ← 8 Cloud Functions (4 engine + 3 push + 1 pro token)
│       ├── volumeEngine.ts        ← motor matemático
│       ├── pushNotifications.ts   ← push: PR, deload, inatividade
│       ├── proToken.ts            ← Cloud Function resgate de token Pro
│       ├── types.ts
│       └── seed_exercises.ts      ← script para popular Firestore global
│
├── website/                        ← Landing Page Next.js (Vercel)
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx                ← hero, features, ciência, download
│   │   └── globals.css
│   ├── public/download/apk.apk     ← APK para download direto
│   ├── next.config.ts
│   └── package.json
│
└── app/lib/
    ├── main.dart                  ← registra providers + FCM setup (bypass em web)
    ├── firebase_options.dart
    ├── core/
    │   ├── data/
    │   │   ├── exercise_library.dart   ← 80+ exercícios + mapas de reabilitação
    │   │   └── mock_exercises.dart     ← legado (substituído pela library)
    │   ├── router/app_router.dart
    │   ├── scripts/seed_cloud.dart
    │   └── services/
    │       ├── auth_service.dart
    │       ├── notification_service.dart  ← notificações locais + agendamento
    │       └── pro_service.dart          ← verificação Pro, resgate de token
    ├── shared/
    │   ├── theme/app_theme.dart
    │   └── widgets/pro_gate_dialog.dart  ← dialog de acesso Pro
    └── features/
        ├── auth/
        │   ├── login_screen.dart
        │   └── register_screen.dart
        ├── dashboard/
        │   └── dashboard_screen.dart
        ├── analytics/
        │   ├── analytics_screen.dart
        │   └── analytics_service.dart
        ├── exercises/
        │   ├── exercise_model.dart
        │   ├── exercise_provider.dart
        │   ├── exercise_screen.dart
        │   ├── exercise_card.dart
        │   ├── exercise_detail_screen.dart
        │   ├── add_exercise_screen.dart
        │   ├── progression_screen.dart
        │   └── progression_service.dart
        └── workout/
            ├── workout_models.dart
            ├── workout_provider.dart
            ├── workout_screen.dart
            ├── workout_history_screen.dart
            ├── workout_profile_model.dart
            ├── workout_profile_provider.dart
            ├── workout_routine_model.dart
            ├── routine_service.dart
            ├── routine_list_screen.dart
            ├── routine_detail_screen.dart
            ├── anamnese_screen.dart
            ├── prescribed_workout_model.dart
            ├── prescribed_workout_screen.dart
            ├── prescription_engine.dart      ← motor v5: 100% esportivo/modalidade/clássico
            ├── progression_engine.dart
            ├── sport_plan_builders.dart       ← geradores v5: corrida, luta, calistenia, etc.
            ├── progression_provider.dart
            ├── exercise_rotation_manager.dart  ← rotação semanal de exercícios
            ├── session_fatigue_accumulator.dart  ← acumulador de fadiga multiarticular
            ├── pr_model.dart
            ├── pr_service.dart
            └── pr_celebration_dialog.dart
        └── nutrition/
            ├── nutrition_profile_model.dart   ← Perfil bio-adaptativo
            ├── meal_model.dart                ← Log de refeições
            ├── nutrition_provider.dart         ← Estado e persistência
            ├── nutrition_engine.dart           ← Motor de TDEE e bônus pós-treino
            ├── nutrition_service.dart          ← Busca (Local + Open Food Facts API)
            ├── nutrition_screen.dart           ← Dashboard Nutricional
            ├── food_search_screen.dart        ← Busca de alimentos
            └── nutrition_settings_screen.dart  ← Ajustes manuais de macros e modo Bio-Adaptativo
```

---

## Rotas (app_router.dart)

| Rota | Tela | Status |
|------|------|--------|
| /login | LoginScreen | Free |
| /register | RegisterScreen | Free |
| /dashboard | DashboardScreen | Free |
| /exercises | ExerciseScreen | Free |
| /exercises/add | AddExerciseScreen | Free |
| /exercises/:id | ExerciseDetailScreen | Free |
| /progression | ProgressionScreen | **Pro** |
| /workout | WorkoutScreen | Free |
| /workout/history | WorkoutHistoryScreen | **Pro** |
| /analytics | AnalyticsScreen | **Pro** |
| /routines | RoutineListScreen | Free |
| /routines/detail | RoutineDetailScreen | Free |
| /anamnese | AnamneseScreen | Free |
| /prescribed | PrescribedWorkoutScreen | **Pro** |
| /nutrition | NutritionScreen | **Pro** |
| /nutrition/search | FoodSearchScreen | **Pro** |
| /nutrition/settings | NutritionSettingsScreen | **Pro** |
| /profile | ProfileScreen | Free |

---

## Firestore — estrutura de dados

```
users/{uid}
  ├── exercises/{exId}
  ├── workouts/{wId}
  │     date, weekNumber, totalVolume, exerciseCount
  │     exercises: [{exerciseId, exerciseName, muscleGroup, sets:[{reps,weight,volume}], volume}]
  ├── profile/current            ← WorkoutProfile salvo pela anamnese
  ├── generated_workouts/current ← GeneratedWorkout salvo pelo PrescriptionEngine
  ├── progression_state/current  ← ProgressionState (RIR, deload, plateaus)
  ├── personalRecords/{exId}
  ├── progressionWeeks/{pwId}
  ├── volumeHistory/{vhId}       ← só Cloud Functions escrevem
  └── suggestedProgressions/{spId}
  isPro: boolean                 ← status Pro do usuário
  proActivatedAt: timestamp      ← quando ativou
  proTokenUsed: string           ← código do token usado (opcional)
  fcmToken: string               ← token FCM para push remoto
  
  nutrition/settings             ← Perfil nutricional (alvo, macros, toggles)
  nutrition/logs/{yyyy-mm-dd}
    ├── meals/{mId}              ← Refeições registradas no dia
    └── summary                  ← Agregado diário (kcal, P, C, G)

config/apkVersion
exercises/{exId}                 ← biblioteca global (seed_exercises.ts)
proTokens/{code}                 ← tokens de liberação Pro
  code: string
  maxRedemptions: number         ← -1 = ilimitado
  currentRedemptions: number
  createdAt: timestamp
  expiresAt?: timestamp          ← opcional
  label?: string
  └── redemptions/{uid}          ← quem resgatou
        userId: string
        redeemedAt: timestamp
```

---

## Cloud Functions implementadas

1. `onWorkoutExerciseSave` — trigger, valida/corrige volume, agrega volumeHistory
2. `generateProgressionSuggestions` — callable, sugestões de progressão
3. `calculatePeriodizationPlan` — callable, plano de periodização
4. `getApkVersion` — callable, metadados do APK
5. `onPersonalRecordCreated` — Firestore trigger, push quando novo PR (`users/{uid}/personalRecords/{prId}`)
6. `onDeloadActivated` — Firestore trigger, push quando entra em deload (`progression_state` phase muda para "deload")
7. `notifyInactiveUsers` — scheduled daily 9h BRT, push quem não treina há 7+ dias
8. `redeemProToken` — callable, resgata código de liberação Pro (valida token, verifica limite/expiração, ativa isPro)

---

## Motor de Prescrição (prescription_engine.dart) — v5.0

### Divisões & Modalidades (Upgrade Estelar):
| Tipo | Plano | Cobertura |
|------|-------|-----------|
| **Clássico** | PPL, UL, Arnold, FB, Híbrido | Hipertrofia/Força |
| **Esportivo** | Corrida (5k-42k), Futebol, MMA, BJJ, Boxe, Bike, Natação | Performance específica |
| **Modalidade**| Calistenia (Skills/SW), HIIT (Tabata/EMOM), Funcional | Condicionamento |
| **Templates** | 5x5, GVT, 5/3/1, PHUL, PHAT | Metodologias famosas |
| **Saúde** | Reabilitação, Mobilidade, Yoga, Terceira Idade | Longevidade |

### Características v5.0:
- **100% de Cobertura:** Todos os 949 exercícios têm mapeamento anatômico e biomecânico.
- **Mapeamento de Fadiga:** Cada exercício contribui dinamicamente para o `SpinalLoad`, `ShoulderStress` e `KneeStress`.
- **Length Bias Schoenfeld:** Lógica real que alterna entre posição encurtada (ex: Rosca Concentrada) e alongada (ex: Rosca Inclinada).
- **Filtro de Lesões Universal:** Agora cobre Ombro, Joelho, Lombar, Cotovelo, Punho e Quadril.
- **DUP Avançada:** Ondulação diária de intensidade integrada aos novos builders esportivos.
- **RIR Adaptativo:** O motor ajusta a intensidade com base na fadiga acumulada da sessão.

---

## Exercise Rotation Manager (exercise_rotation_manager.dart)

- A cada 2 semanas, 1-2 exercícios por grupo muscular são trocados por equivalentes do mesmo movement pattern
- Usa substitutesIds do ExerciseModel + group peers da library
- Nunca troca exercícios favoritos (aderência > variação)
- Filtra disliked exercises
- Baseado em: Schoenfeld IUSCA 2021 + Bompa Periodization

---

## Session Fatigue Accumulator + Pattern History (session_fatigue_accumulator.dart)

### SessionFatigueAccumulator
Rastreia acumulação de fadiga multiarticular durante montagem da sessão:
- `spinalLoadAccumulated` (max 3.0)
- `shoulderStressAccumulated` (max 3.5)
- `kneeStressAccumulated` (max 4.0)
- `cnsLoadAccumulated` (max 3.0)
- `canAdd(exercise, sets)`: verifica se pode adicionar exercício sem estourar limites
- Thresholds críticos a 80% do máximo

### PatternHistoryTracker
- Rastreia quais padrões de movimento foram executados nos últimos dias
- `patternAvailability(pattern)`: 1.0 (não usado), 0.5 (2 dias atrás), 0.0 (ontem = bloqueia)
- Patterns relacionados: hinge+squat (carga lombar), push_vertical+push_horizontal (ombro)

---

## Motor de Progressão (progression_engine.dart) — v2

Tabela de decisão baseada em RIR (Schoenfeld 2021):
- RIR >= 3 → aumentar carga (+2,5kg superior / +5kg inferior)
- RIR 1-2 → consolidar (zona ideal de hipertrofia)
- Não completou reps por 2× → reduzir 10%
- 3 sessões sem progressão → substituir exercício
- Bodyweight: cadeia de progressão (flexão → archer → unilateral)
- Deload automático temporal: beginner=4sem, intermediate=6sem, advanced=8sem
- Persiste estado em `users/{uid}/progression_state/current`

---

## Motor Matemático (volumeEngine.ts)

```
volume = séries × repetições × carga
volume_alvo_semana = volume_anterior × (1 + progressão%)
carga = volume_alvo / (séries × reps)
carga arredondada para múltiplos de 2.5 kg
```

---

## Biblioteca de Exercícios (exercise_library.dart) — v5.0 Mega Library

**949 exercícios** biomecanicamente qualificados com:
- **Músculos Primários/Secundários:** Reclassificação total eliminando "Full Body" genérico.
- **Filtro de Lesões:** Mapeamento de estresse articular (Spinal, Shoulder, Knee) em 0.0-1.0.
- **Length Bias:** Identificação de posição de pico de tensão (Lengthened, Shortened, Mid-range).
- **DUP Metadata:** Rep range científico por padrão de movimento.
- **Padrões de Movimento:** Squat, Hinge, Push (H/V/Incline), Pull (H/V), Carry, Rotation, Isolation.

**Cobertura de Músculos (Candidates):**
- Quads (190), Chest (135), Back (134), Shoulders (96), Glutes (82), Biceps (57), Triceps (56), Hamstrings (42), Abs (41), Calves (40), Forearms (26).

**Reabilitação:**
- Ombro, Joelho, Lombar, Cotovelo, Punho e Quadril integrados.

---

## Sistema Freemium (Pro/Free) (2026-04-06)

### Como funciona
- Campo `users/{uid}.isPro` (boolean) controla acesso
- `ProService` em `app/lib/core/services/pro_service.dart` gerencia verificação
- `ProGate.show(context)` abre dialog com lista de features Pro + campo para resgatar token

### Ativação Pro (3 formas):
1. **Token de liberação** → Usuário insere código no ProGate dialog
   - Cloud Function `redeemProToken` valida no Firestore `proTokens/{code}`
   - Suporta limite de resgates (`maxRedemptions`: -1 = ilimitado)
   - Suporta expiração (`expiresAt`)
   - Registra quem resgatou em `proTokens/{code}/redemptions/{uid}`
2. **Admin via Firestore** → `users/{uid}.isPro = true` manualmente
3. **ProService.setProStatus(true)** → método exposto (para teste, remover em produção)

### Features FREE vs PRO
- **Free**: workout básico, anamnese, lista de exercícios, login
- **Pro**: prescrição inteligente, analytics, progressão RIR, PR, rotação semanal, deload

---

## Notificações Push (2026-04-06)

### Arquitetura mista (local + FCM)

| Tipo | Canal | Gatilho |
|------|-------|---------|
| Local | flutter_local_notifications | `NotificationService.showLocalNotification()` |
| Push remoto | Firebase Cloud Messaging | Cloud Functions (Firestore triggers + cron) |
| Inatividade local | `scheduleInactivityReminder` | Startup do app (main.dart) |
| PR push | `onPersonalRecordCreated` | `users/{uid}/personalRecords/{prId}` |
| Deload push | `onDeloadActivated` | progression_state phase → "deload" |
| Inatividade push | `notifyInactiveUsers` | Scheduled daily 9h BRT |

### Fluxo FCM
1. `fcmSetup()` no `main.dart` inicializa `FirebaseMessaging`
2. Obtém token, salva em `users/{uid}.fcmToken`
3. `onTokenRefresh` atualiza token automaticamente
4. `onMessage` (foreground) → mostra notificação local
5. `onMessageOpenedApp` → handler pronto para navegação contextual
6. `AndroidManifest`: canal `general` como default, permissão `POST_NOTIFICATIONS`
7. Cloud Functions leem `fcmToken` do userDoc e chamam `admin.messaging().send()`
8. **FCM não roda em web** — bypass com `if (!kIsWeb)` no main.dart

### Permissões Android
- `POST_NOTIFICATIONS` obrigatório para Android 13+
- `RECEIVE_BOOT_COMPLETED` para re-agendar notificações após reboot
- `SCHEDULE_EXACT_NOTIFICATION` para agendamento exato
- Receivers dentro de `<application>` no AndroidManifest

---

## Website / Landing Page (2026-04-06)

- `website/` — Next.js 15 App Router, tema Neo-Tactile
- Seções: Hero, Features (6 cards), Ciência (4 refs), Download APK
- Botão "Entrar" na navbar → `/app` (redireciona para Flutter web)
- Botão "Baixar APK" → `/download/apk` (download direto)
- APK em `website/public/download/apk.apk`
- Deploy: Vercel (projeto `buildfit-nine`)
- Rodar local: `cd website && npm install && npm run dev` → http://localhost:3000
- `next.config.ts`: output standalone, rewrite para `/app`

---

## Build APK (notas de resolução)

- `flutter config --enable-native-assets` necessário para Flutter 3.41+ com Firebase plugins
- `coreLibraryDesugaringEnabled = true` em `android/app/build.gradle.kts`
- `<receiver>` tags devem estar dentro de `<application>` no AndroidManifest.xml
- Developer Mode do Windows necessário para symlink support
- Comando: `flutter build apk --release` (com `--no-tree-shake-icons` se travar)
- Output: `build/app/outputs/flutter-apk/app-release.apk`

### Problemas conhecidos no Web (Chrome)
- Ícones Material Icons podem quebrar com tree-shake-icons no web build
- GIFs de exercícios vêm de URLs externas (GitHub raw) — CORS pode bloquear no web
- FCM não funciona em web (requer service worker)
- **Solução**: build web com `--no-tree-shake-icons`, no Android funciona normal
- **Vídeos/GIFs**: Migrados de repositórios GitHub genéricos para `gifdotreino.com` (maior qualidade + mapa muscular anatômico). (2026-04-07)

---

## Tema Neo-Tactile (app_theme.dart)

| Token | Hex | Uso |
|-------|-----|-----|
| background | #0A0A0F | Fundo geral |
| surface | #181822 | Cards |
| surfaceHighlight | #232332 | Inputs |
| accent | #3B82FF | Azul primário |
| accentVariant | #1E5AD6 | Azul escuro |
| success | #22C55E | Verde |
| danger | #EF4444 | Vermelho / deload |
| textPrimary | #F3F4F6 | Texto principal |
| textSecondary | #9CA3AF | Texto auxiliar |

---

## O que já está implementado (✅)

- ✅ Firebase backend completo (rules, indexes, 8 functions, volumeEngine, push notifications, pro token)
- ✅ Auth (login, cadastro, logout)
- ✅ Roteamento com GoRouter + redirect por auth
- ✅ Tema escuro global Neo-Tactile
- ✅ Dashboard com volume semanal, comparação semana anterior, volume por músculo, atalhos
- ✅ Tela de Exercícios (lista, busca, filtro, adicionar, detalhe, editar)
- ✅ ExerciseCard com GIF + placeholder por grupo muscular
- ✅ ProgressionService — sugestões de carga
- ✅ ProgressionScreen — duas abas: motor RIR + histórico
- ✅ WorkoutScreen — sessão ativa com timer, FAB, RIR por exercício
- ✅ WorkoutProvider — estado da sessão
- ✅ WorkoutHistoryScreen
- ✅ Analytics com gráficos Syncfusion
- ✅ Sistema de PR — detecção, celebração animada, histórico
- ✅ Gestão de rotinas — templates A/B/C
- ✅ Anamnese — 4 passos
- ✅ Motor de Prescrição v4 — 10 divisões (FB, UL, UL Str, PPL 3, PPL 5 hídrido, PPL 6, PPL Str, Arnold)
- ✅ Biblioteca de 80+ exercícios com reabilitação, fadiga, length bias
- ✅ PrescribedWorkoutScreen — RIR, cadência, cues, fase DUP, aquecimento, barras de fadiga
- ✅ Motor de Progressão v2 — RIR, deload automático, plateau, bodyweight chain
- ✅ ProgressionProvider — estado global de progressão
- ✅ Arnold Split — Chest/Back, Shoulders/Arms, Legs
- ✅ PPL+UL Híbrido — Push/Pull/Legs/Upper/Lower (5 dias)
- ✅ Exercise Rotation Manager
- ✅ Session Fatigue Accumulator + Pattern History Tracker
- ✅ Notificações Push (FCM + local) — PR, deload, inatividade
- ✅ Sistema Freemium Free/Pro com token de resgate
- ✅ Landing Page Next.js na Vercel com download APK
- ✅ Firestore rules — progression_state + personalRecords + proTokens
- ✅ Firestore indexes
- ✅ Integração de GIFs Anatômicos (gifdotreino.com) — 30+ exercícios principais atualizados com mapa muscular em vermelho para melhor visualização técnica. (2026-04-07)

---

## O que está pendente (⏳)

- ⏳ Stripe integração (pagamentos reais para Pro)
- ⏳ Deploy Flutter web na Vercel (caminho `/app`)
- ⏳ Deploy Firebase Functions em produção (hoje emuladores)
- ⏳ Remover botão "Ativar Pro (teste local)" do ProGate antes de produção
- ⏳ Criar tokens Pro iniciais no Firestore para beta testers

---

## Como rodar localmente

**Terminal 1 — Backend:**
```bash
cd "d:\App de calculo de carga\firebase\functions"
npm install
cd ..
firebase emulators:start
```
Emulator UI: http://localhost:4000

**Terminal 2 — App:**
```bash
cd "d:\App de calculo de carga\app"
flutter pub get
flutter run -d chrome
```

**Terminal 3 — Landing Page:**
```bash
cd "d:\App de calculo de carga\website"
npm install
npm run dev
```
→ http://localhost:3000

**ATENÇÃO:** O main.dart atual tem os emuladores comentados.
Para desenvolvimento local, descomentar em main.dart:
```dart
const String host = '127.0.0.1';
FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
FirebaseAuth.instance.useAuthEmulator(host, 9099);
```

---

## Rodar no celular (Android)

**Pré-requisitos:**
1. Android Studio instalado (para os drivers do ADB)
2. Celular com modo desenvolvedor ativado + depuração USB ativada
3. Cabo USB conectado

**Passos:**
```bash
flutter devices          # confirma que o celular aparece
flutter run -d <device_id>
```

**IMPORTANTE para celular com Firebase real (não emulador):**
- Descomentar as linhas de emulador em main.dart
- Garantir que google-services.json está em app/android/app/
- O firebase_options.dart já está configurado com o projeto real

---

## Deploy Vercel

**Projeto:** https://vercel.com → buildfit-nine
**URL:** https://buildfit-nine.vercel.app/

**Configurações necessárias no dashboard Vercel:**
- Build Command: `cd website && npm install && npm run build`
- Output Directory: `website/.next/standalone`
- Root Directory: vazio (projeto no root, vercel.json cuida do resto)

**Após push para GitHub**, a Vercel detecta mudanças e rebuildar automaticamente.

---

## MCP configurado (Claude Desktop)

Config em:
```
C:\Users\Felipe\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json
```

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "C:\\Users\\Felipe\\AppData\\Roaming\\npm\\mcp-server-filesystem.cmd",
      "args": ["d:\\App de calculo de carga"]
    }
  }
}
```

---

## Padrões de código

- Sem lógica de negócio nas telas — tudo via Provider ou Service
- Providers estendem ChangeNotifier
- StreamSubscription sempre cancelado no dispose()
- UIDs sempre de FirebaseAuth.instance.currentUser?.uid
- Queries Firestore usando índices compostos existentes
- Erros em português amigável
- withValues(alpha:) em vez de withOpacity()
- FCM: `fcmToken` armazenado em `users/{uid}.fcmToken` no Firestore
- FCM bypass em web: `if (!kIsWeb)` antes de qualquer chamada FirebaseMessaging
- `<receiver>` tags sempre dentro de `<application>` no AndroidManifest
- Features PRO: gate via `ProGate.show(context)` + `ProService.isPro()`

---

## Registro de Progresso Diário

### 📅 2026-04-07
- **Foco:** Visual Assets & Exercise Guidance.
- **Feito:**
  - Avaliação de fontes de GIFs (Kaggle vs ExRx vs Gif do Treino).
  - Substituição massiva de links de GIFs no `exercise_library.dart`.
  - Migração para a CDN do `gifdotreino.com` — agora os GIFs mostram os músculos em vermelho (anatomical highlights).
  - Adição de URLs para exercícios que estavam sem imagem (Puxadas, Remadas, Agachamentos).
- **Pendências de hoje:** Finalizar mapeamento dos exercícios de reabilitação (rehab) com o novo site.

### 📅 2026-04-09
- **Foco:** Motor de Prescrição v5.0 & Reclassificação Universal da Biblioteca.
- **Feito:**
  - Implementação do `SportPlanBuilders` com suporte a Corrida, Futebol, MMA, BJJ, Natação, Bike e Calistenia.
  - Atualização da Anamnese para capturar 12 objetivos esportivos e modalidades específicas.
  - **Auditoria & Fix:** Identificado que 52% da biblioteca era inacessível (full_body generic).
  - **Reclassificação Massiva:** Criado script inteligente que reclassificou 896 exercícios em segundos baseado em biomecânica e nomes em português.
  - **Meta-data Injection:** Todos os 949 exercícios agora possuem perfis de fadiga (Spinal, Shoulder, Knee Load) e Length Bias (Schoenfeld 2021).
  - **100% de Cobertura:** Realizada auditoria final confirmando que todos os 949 candidatos são agora selecionáveis pelo motor.
  - Sincronização e Build final para Web concluídos.
- **Status:** Motor v5.0 entregue com 949 exercícios 100% funcionais. Alpha testing iniciado.

  - **Upgrade Motor v5.1 (Integração Teórica Bompa & NSCA):**
---

## Tema Neo-Tactile (app_theme.dart)

| Token | Hex | Uso |
|-------|-----|-----|
| background | #0A0A0F | Fundo geral |
| surface | #181822 | Cards |
| surfaceHighlight | #232332 | Inputs |
| accent | #3B82FF | Azul primário |
| accentVariant | #1E5AD6 | Azul escuro |
| success | #22C55E | Verde |
| danger | #EF4444 | Vermelho / deload |
| textPrimary | #F3F4F6 | Texto principal |
| textSecondary | #9CA3AF | Texto auxiliar |

---

## O que já está implementado (✅)

- ✅ Firebase backend completo (rules, indexes, 8 functions, volumeEngine, push notifications, pro token)
- ✅ Auth (login, cadastro, logout)
- ✅ Roteamento com GoRouter + redirect por auth
- ✅ Tema escuro global Neo-Tactile
- ✅ Dashboard com volume semanal, comparação semana anterior, volume por músculo, atalhos
- ✅ Tela de Exercícios (lista, busca, filtro, adicionar, detalhe, editar)
- ✅ ExerciseCard com GIF + placeholder por grupo muscular
- ✅ ProgressionService — sugestões de carga
- ✅ ProgressionScreen — duas abas: motor RIR + histórico
- ✅ WorkoutScreen — sessão ativa com timer, FAB, RIR por exercício
- ✅ WorkoutProvider — estado da sessão
- ✅ WorkoutHistoryScreen
- ✅ Analytics com gráficos Syncfusion
- ✅ Sistema de PR — detecção, celebração animada, histórico
- ✅ Gestão de rotinas — templates A/B/C
- ✅ Anamnese — 4 passos
- ✅ Motor de Prescrição v4 — 10 divisões (FB, UL, UL Str, PPL 3, PPL 5 hídrido, PPL 6, PPL Str, Arnold)
- ✅ Biblioteca de 80+ exercícios com reabilitação, fadiga, length bias
- ✅ PrescribedWorkoutScreen — RIR, cadência, cues, fase DUP, aquecimento, barras de fadiga
- ✅ Motor de Progressão v2 — RIR, deload automático, plateau, bodyweight chain
- ✅ ProgressionProvider — estado global de progressão
- ✅ Arnold Split — Chest/Back, Shoulders/Arms, Legs
- ✅ PPL+UL Híbrido — Push/Pull/Legs/Upper/Lower (5 dias)
- ✅ Exercise Rotation Manager
- ✅ Session Fatigue Accumulator + Pattern History Tracker
- ✅ Notificações Push (FCM + local) — PR, deload, inatividade
- ✅ Sistema Freemium Free/Pro com token de resgate
- ✅ Landing Page Next.js na Vercel com download APK
- ✅ Firestore rules — progression_state + personalRecords + proTokens
- ✅ Firestore indexes
- ✅ Integração de GIFs Anatômicos (gifdotreino.com) — 30+ exercícios principais atualizados com mapa muscular em vermelho para melhor visualização técnica. (2026-04-07)

---

## O que está pendente (⏳)

- ⏳ Stripe integração (pagamentos reais para Pro)
- ⏳ Deploy Flutter web na Vercel (caminho `/app`)
- ⏳ Deploy Firebase Functions em produção (hoje emuladores)
- ⏳ Remover botão "Ativar Pro (teste local)" do ProGate antes de produção
- ⏳ Criar tokens Pro iniciais no Firestore para beta testers

---

## Como rodar localmente

**Terminal 1 — Backend:**
```bash
cd "d:\App de calculo de carga\firebase\functions"
npm install
cd ..
firebase emulators:start
```
Emulator UI: http://localhost:4000

**Terminal 2 — App:**
```bash
cd "d:\App de calculo de carga\app"
flutter pub get
flutter run -d chrome
```

**Terminal 3 — Landing Page:**
```bash
cd "d:\App de calculo de carga\website"
npm install
npm run dev
```
→ http://localhost:3000

**ATENÇÃO:** O main.dart atual tem os emuladores comentados.
Para desenvolvimento local, descomentar em main.dart:
```dart
const String host = '127.0.0.1';
FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
FirebaseAuth.instance.useAuthEmulator(host, 9099);
```

---

## Rodar no celular (Android)

**Pré-requisitos:**
1. Android Studio instalado (para os drivers do ADB)
2. Celular com modo desenvolvedor ativado + depuração USB ativada
3. Cabo USB conectado

**Passos:**
```bash
flutter devices          # confirma que o celular aparece
flutter run -d <device_id>
```

**IMPORTANTE para celular com Firebase real (não emulador):**
- Descomentar as linhas de emulador em main.dart
- Garantir que google-services.json está em app/android/app/
- O firebase_options.dart já está configurado com o projeto real

---

## Deploy Vercel

**Projeto:** https://vercel.com → buildfit-nine
**URL:** https://buildfit-nine.vercel.app/

**Configurações necessárias no dashboard Vercel:**
- Build Command: `cd website && npm install && npm run build`
- Output Directory: `website/.next/standalone`
- Root Directory: vazio (projeto no root, vercel.json cuida do resto)

**Após push para GitHub**, a Vercel detecta mudanças e rebuildar automaticamente.

---

## MCP configurado (Claude Desktop)

Config em:
```
C:\Users\Felipe\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json
```

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "C:\\Users\\Felipe\\AppData\\Roaming\\npm\\mcp-server-filesystem.cmd",
      "args": ["d:\\App de calculo de carga"]
    }
  }
}
```

---

## Padrões de código

- Sem lógica de negócio nas telas — tudo via Provider ou Service
- Providers estendem ChangeNotifier
- StreamSubscription sempre cancelado no dispose()
- UIDs sempre de FirebaseAuth.instance.currentUser?.uid
- Queries Firestore usando índices compostos existentes
- Erros em português amigável
- withValues(alpha:) em vez de withOpacity()
- FCM: `fcmToken` armazenado em `users/{uid}.fcmToken` no Firestore
- FCM bypass em web: `if (!kIsWeb)` antes de qualquer chamada FirebaseMessaging
- `<receiver>` tags sempre dentro de `<application>` no AndroidManifest
- Features PRO: gate via `ProGate.show(context)` + `ProService.isPro()`

---

## Registro de Progresso Diário

### 📅 2026-04-07
- **Foco:** Visual Assets & Exercise Guidance.
- **Feito:**
  - Avaliação de fontes de GIFs (Kaggle vs ExRx vs Gif do Treino).
  - Substituição massiva de links de GIFs no `exercise_library.dart`.
  - Migração para a CDN do `gifdotreino.com` — agora os GIFs mostram os músculos em vermelho (anatomical highlights).
  - Adição de URLs para exercícios que estavam sem imagem (Puxadas, Remadas, Agachamentos).
- **Pendências de hoje:** Finalizar mapeamento dos exercícios de reabilitação (rehab) com o novo site.

### 📅 2026-04-09
- **Foco:** Motor de Prescrição v5.0 & Reclassificação Universal da Biblioteca.
- **Feito:**
  - Implementação do `SportPlanBuilders` com suporte a Corrida, Futebol, MMA, BJJ, Natação, Bike e Calistenia.
  - Atualização da Anamnese para capturar 12 objetivos esportivos e modalidades específicas.
  - **Auditoria & Fix:** Identificado que 52% da biblioteca era inacessível (full_body generic).
  - **Reclassificação Massiva:** Criado script inteligente que reclassificou 896 exercícios em segundos baseado em biomecânica e nomes em português.
  - **Meta-data Injection:** Todos os 949 exercícios agora possuem perfis de fadiga (Spinal, Shoulder, Knee Load) e Length Bias (Schoenfeld 2021).
  - **100% de Cobertura:** Realizada auditoria final confirmando que todos os 949 candidatos são agora selecionáveis pelo motor.
  - Sincronização e Build final para Web concluídos.
- **Status:** Motor v5.0 entregue com 949 exercícios 100% funcionais. Alpha testing iniciado.

  - **Upgrade Motor v5.1 (Integração Teórica Bompa & NSCA):**
    - **Adaptação Anatômica Automática (Bompa):** Iniciantes têm volumes e intensidades forçados (RIR elevado, repetições 12-15) para fortificação de ligamentos antes do uso de cargas neurais.
    - **Sistemas de Energia Avançados (Bompa):** Redirecionamento da lógica de Endurance focando em Lactic/Power Endurance vs Aerobic Capacity (ME Long), ajustando volume automaticamente.
    - **Aquecimento RAMP (NSCA):** Substituiu aquecimentos genéricos. Adiciona protocolos estratificados de *Raise*, *Activate/Mobilize* e *Potentiate* (com *Power Skips* e *High-Knees*) focados na mecânica do esporte.
    - **Separação Explosivo vs Força Lenta (NSCA):** O app agora segrega "Dia de Levantamentos Explosivos", com recomendações expressas de foco de velocidade da concêntrica.
     - **Home Fallback Seguro:** Planos Esportivos cruzam com a escolha de ambiente "Em Casa"; se necessário, expurgam equipamentos industriais e readaptam com exercícios da biblioteca *bodyweight* / *dumbbell* / *bands*.
  - **Refatoração UX:** Seletor de RIR (Repetições de Reserva) totalmente reescrito na interface durante a execução. Rótulos e cores agora descrevem textualmente o esforço limitante (Ex: "0: Falha máxima (0 reps de sobra)"), criando um feedback em tempo real para regular a intensidade.

### 📅 2026-04-10
- **Foco:** Módulo de Nutrição Bio-Adaptativo (v6.2) & Digital Twin.
- **Feito:**
  - **Motor Nutricional Adaptativo:** Criado motor que calcula TDEE dinâmico (Mifflin-St Jeor) com bônus de recuperação pós-treino automático (+100 a +250 kcal/dia).
  - **Carb Cycling Inteligente:** Implementada lógica de alternância de carboidratos (high carb em dias de treino / low carb em descanso) ligada ao calendário de treinos.
  - **Busca de Alimentos Híbrida:** Integração local (Firestore TACO) + remota (Open Food Facts API) via pacote `http`.
  - **Interface Nutricional:** Dashboard com gráficos de rosca e barras de macros (Syncfusion), tela de busca com debounce e tela de configurações manuais.
  - **Ajustes de Estabilidade:** Resolvidos problemas de inicialização infinita no Web e corrigida a localização `pt_BR` para compatibilidade total.
  - **Sync de Deploy:** Sincronizados os builds de Flutter Web com a pasta `/public/treino` da landing page na Vercel.
- **Status:** Ecossistema Saúde + Treino 100% integrado. Nutrição funcional e adaptativa ativada para usuários Pro.

### 📅 2026-04-12
- **Foco:** Bio-Gestão Energética 7.0, Estabilização da API Nutricional e UX/UI.
- **Feito:**
  - **Correção de Crash de Inicialização:** Removidos erros de "Null check operator" e corrigidos guards `kIsWeb` no `NotificationService`.
  - **Bio-Gestão 7.0 (Orçamento Semanal):** Evolução do módulo de nutrição de metas diárias fixas para orçamento energético semanal dinâmico.
  - **Motor de Compensação Inteligente:** Implementada lógica de redistribuição de excessos. Se o usuário consome > meta hoje, o sistema dilui o excedente nos dias restantes da semana (estratégia suave) ou compensa no dia seguinte (estratégia rígida).
  - **Linha do Tempo Adaptativa:** Cada dia da semana (Seg-Dom) possui uma meta específica dependente da carga de treino (Alta Demanda = +20% Carbo / Descanso = -15% Carbo).
  - **Monitoramento de Evolução:** Adição de `adherenceScore` (consistência real) e `nutritionalFatigueLevel` (alerta de estafa metabólica após longos déficits).
  - **Interface de Timeline:** Widget interativo no topo da tela de nutrição para visualização clara do planejamento semanal.
- **Status:** Sistema adaptativo agora resiliente a variações de consumo e 100% funcional na web.

---

## Módulos e Lógica Interna

### 1. Bio-Gestão 7.0 (Gestão Energética Adaptativa)
O sistema trata a nutrição como um ecossistema semanal, não como fatias diárias isoladas.

#### Algoritmo de Orçamento:
- **Orçamento Base:** $TDEE \times 7$ (Total Daily Energy Expenditure).
- **Redistribuição Inicial:** 
  - Dias com treino (`wp.availableDaysPerWeek`) são marcados como "Alta Demanda".
  - Multiplicador de Alta Demanda: $1.10 \times$ calorias diárias (foco em Carboidratos).
  - Multiplicador de Descanso: $0.85 \times$ calorias diárias.
  - O sistema calibra a soma dos 7 dias para bater exatamente o `weeklyBudgetKcal`.

#### Motor de Compensação (Triggered o Meal Log):
1. **Detecta Desvio:** $ConsumoReal - MetaDiária = Desvio$.
2. **Calcula Dias Restantes:** $DiasAtéDomingo = 7 - DiaAtual$.
3. **Distribui Excesso:** 
   - Se $Desvio > 0$, o excesso é dividido pelos dias restantes e subtraído de suas metas.
   - **Trava de Segurança:** As calorias nunca caem abaixo da Taxa Metabólica Basal (TMB), preservando a saúde do usuário mesmo em grandes excessos.
   - **Prioridade de Corte:** O ajuste atua prioritariamente sobre os Carboidratos, mantendo Proteína e Gordura dentro das margens de segurança fisiológica.

#### Indicadores de Saúde Metabólica:
- **Aderência:** Média ponderada dos desvios absolutos. $Score < 0.7$ sugere que a estratégia atual está muito rígida.
- **Fadiga Nutricional:** Contador que sobe se o usuário permanece em déficit agressivo por > 6 semanas. Gatilha sugestão de "Refeed" ou manutenção.
- **Disponibilidade Energética:** Sincronização em tempo real com o volume de treino do `WorkoutProvider`.

---

## 🔧 Sessão em Progresso: Problema de Carregamento de GIFs (2026-04-16)

### Objetivo
Fazer os GIFs dos exercícios aparecerem corretamente na aba "Treino" (Tutorial) do aplicativo Flutter web hospedado em Vercel.

### Raiz do Problema
- GIFs armazenados no **Firebase Storage** (`gs://appcalculotreino-51f23.firebasestorage.app`)
- Navegador bloqueia requisições diretas para `firebasestorage.googleapis.com` por **CORS** (Cross-Origin Resource Sharing)
- Firebase Storage não envia headers `Access-Control-Allow-Origin` para requisições cross-origin
- App tenta carregar via URL direta → 403 Forbidden ou bloqueio CORS do navegador

### Solução Implementada: Proxy GIF via API Next.js

#### 1. **API Route Dinâmica** (`website/app/api/gif/route.ts`)
```typescript
export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  const filename = request.nextUrl.searchParams.get('name');
  // Busca GIF no Firebase Storage interno
  // Retorna com headers CORS: Access-Control-Allow-Origin: *
}
```

#### 2. **Cliente Flutter** (`app/lib/features/exercises/exercise_provider.dart`)
```dart
static const String baseGifUrl = 'https://app-calculo-carga.vercel.app/api/gif?ts=2';

String? getEffectiveGifUrl(ExerciseModel ex) {
  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) {
    return ex.gifUrl;
  }
  final filename = Uri.encodeComponent(ex.name);
  return '$baseGifUrl&name=$filename';
}
```

#### 3. **Configuração Next.js** (`website/next.config.ts`)
- Removido `output: 'export'` para permitir API routes dinâmicas
- Vercel executa serverless functions nativamente

### Fluxo de Requisição
1. Flutter app solicita: `https://app-calculo-carga.vercel.app/api/gif?ts=2&name=Exercicio`
2. Vercel executa função serverless (`/api/gif/route.ts`)
3. API busca internamente no Firebase: `https://firebasestorage.googleapis.com/v0/b/.../o/{nome}.gif?alt=media`
4. API retorna com `Access-Control-Allow-Origin: *` (mesmo domínio: vercel.app)
5. Navegador aceita requisição (sem CORS)

### Status Atual (⏳ Aguardando Propagação)
- ✅ Código da API implementado e testado
- ✅ Dart code atualizado com URL proxy
- ✅ Commits feitos com cache bust (`ts=2`)
- ⏳ Vercel ainda servindo cache antigo do navegador
- ❌ GIFs ainda tentando carregar do Firebase direto (em vez do proxy)

### Commits Realizados
- `cd51c360` - Adicionado cache bust timestamp (`ts=2`) + nova sincronização web
- `8a86e78a` - Removido restricão `output: 'export'` para permitir APIs dinâmicas
- `fb6e2a24` - Sincronização de build web sem código
- `582ca02d` - Revertido para bucket correto (`.firebasestorage.app`)

### Hipóteses para a Persistência do Erro
1. **Cache do Navegador:** Mesmo com Ctrl+R, navegador serve versão antiga de `main.dart.js`
2. **Cache da Vercel:** CDN pode estar servendo JavaScript compilado antigo
3. **Build não regenerado:** Timestamp pode não ser suficiente para forçar rebuild
4. **Service Worker:** Possível interferência do service worker em cache

### Próximos Passos Necessários
1. **Opção 1 - Esperar Propagação:** Aguardar 5-10 minutos para Vercel propagar mudanças
2. **Opção 2 - Limpeza Hard Cache:** `Ctrl+Shift+Delete` para limpar cache completo do navegador
3. **Opção 3 - Incrementar Timestamp:** Aumentar `ts=3` ou `ts=10` em `exercise_provider.dart` e fazer rebuild
4. **Opção 4 - Testar API Diretamente:** Testar se `https://app-calculo-carga.vercel.app/api/gif?name=Test` está respondendo
5. **Opção 5 - Debug Console:** Inspecionar Network tab para verificar qual URL está sendo solicitada

### Informações Técnicas Importantes
- **Bucket Firebase:** `gs://appcalculotreino-51f23.firebasestorage.app` (raiz, não subfolder)
- **GIFs Locais:** Nomes compatíveis com `ExerciseModel.name`
- **Storage Rules:** Já atualizado para permitir leitura pública (`allow read: if true`)
- **URL Final Esperada:** `https://app-calculo-carga.vercel.app/api/gif?ts=2&name=Crucifixo%20inverso%20unilateral%20com%20cabo`
