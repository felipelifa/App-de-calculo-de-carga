# Contexto do Projeto — App de Treino

## O que é o projeto
App mobile de controle de treino com progressão automática e sistema adaptativo.
Stack: Flutter (Dart) + Firebase (Firestore, Auth, Cloud Functions).
Tema: Dark "Neo-Tactile".

---

## Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter / Dart SDK ^3.11.4 |
| Backend | Firebase (Firestore, Auth, Functions, Storage) |
| Cloud Functions | TypeScript + Node.js ≥ 18 |
| Roteamento | go_router ^17 |
| Estado | provider ^6 |
| Fontes | google_fonts (Inter) |
| Gráficos | syncfusion_flutter_charts |
| Animações | flutter_animate |
| Imagens | cached_network_image |
| Datas | intl ^0.19.0 |

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
│       ├── index.ts               ← 4 Cloud Functions
│       ├── volumeEngine.ts        ← motor matemático
│       ├── types.ts
│       └── seed_exercises.ts      ← script para popular Firestore global
│
└── app/lib/
    ├── main.dart                  ← registra todos os providers
    ├── firebase_options.dart
    ├── core/
    │   ├── data/
    │   │   ├── exercise_library.dart   ← 80+ exercícios + mapas de reabilitação
    │   │   └── mock_exercises.dart     ← legado (substituído pela library)
    │   ├── router/app_router.dart
    │   ├── scripts/seed_cloud.dart
    │   └── services/auth_service.dart
    ├── shared/theme/app_theme.dart
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
        │   ├── exercise_model.dart         ← modelo profissional com restrictions/cues
        │   ├── exercise_provider.dart
        │   ├── exercise_screen.dart
        │   ├── exercise_card.dart
        │   ├── exercise_detail_screen.dart
        │   ├── add_exercise_screen.dart
        │   ├── progression_screen.dart
        │   └── progression_service.dart
        └── workout/
            ├── workout_models.dart
            ├── workout_provider.dart        ← integra ProgressionEngine no finishSession
            ├── workout_screen.dart
            ├── workout_history_screen.dart
            ├── workout_profile_model.dart   ← WorkoutProfile (anamnese completa)
            ├── workout_profile_provider.dart
            ├── workout_routine_model.dart
            ├── routine_service.dart
            ├── routine_list_screen.dart
            ├── routine_detail_screen.dart
            ├── anamnese_screen.dart         ← 4 passos: pessoal, experiência, objetivos, restrições
            ├── prescribed_workout_model.dart ← PrescribedExercise + PrescribedSession + GeneratedWorkout
            ├── prescribed_workout_screen.dart ← exibe RIR, cadência, cues expansíveis, fase DUP
            ├── prescription_engine.dart      ← motor v2: FB/UL/PPL, seleção determinística, reabilitação
            ├── progression_engine.dart       ← motor de progressão: RIR, deload, plateau, bodyweight chain
            ├── progression_provider.dart     ← expõe estado de progressão para UI
            ├── pr_model.dart
            ├── pr_service.dart
            └── pr_celebration_dialog.dart
```

---

## Rotas (app_router.dart)

| Rota | Tela |
|------|------|
| /login | LoginScreen |
| /register | RegisterScreen |
| /dashboard | DashboardScreen |
| /exercises | ExerciseScreen |
| /exercises/add | AddExerciseScreen |
| /exercises/:id | ExerciseDetailScreen |
| /progression | ProgressionScreen |
| /workout | WorkoutScreen |
| /workout/history | WorkoutHistoryScreen |
| /analytics | AnalyticsScreen |
| /routines | RoutineListScreen |
| /routines/detail | RoutineDetailScreen |
| /anamnese | AnamneseScreen |
| /prescribed | PrescribedWorkoutScreen |

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

config/apkVersion
exercises/{exId}                 ← biblioteca global (seed_exercises.ts)
```

---

## Cloud Functions implementadas

1. `onWorkoutExerciseSave` — trigger, valida/corrige volume, agrega volumeHistory
2. `generateProgressionSuggestions` — callable, sugestões de progressão
3. `calculatePeriodizationPlan` — callable, plano de periodização
4. `getApkVersion` — callable, metadados do APK

---

## Motor de Prescrição (prescription_engine.dart) — v2

- Divisões: Full Body, Upper/Lower, PPL 3/5/6 dias, variantes de força
- Seleção determinística por seed do uid (sem Random()) — mesma pessoa = mesmo treino, pessoas diferentes = treinos diferentes
- Variação A/B garantida via slot (exercícios alternam entre sessões)
- Filtro de lesões: remove exercícios agravantes + injeta bloco de reabilitação
- Volume científico (Israetel MEV/MAV) por nível e objetivo
- DUP real: rep range varia entre sessões (força 4×6 / hipertrofia 3×10 / resistência 2×15)
- Cadência prescrita por exercício (1-0-1 / 2-0-2 / 3-1-3)
- RIR correto por objetivo
- Equilíbrio push:pull garantido

---

## Motor de Progressão (progression_engine.dart) — v2

Tabela de decisão baseada em RIR (Schoenfeld 2021):
- RIR >= 3 → aumentar carga (+2,5kg superior / +5kg inferior)
- RIR 1-2 → consolidar (zona ideal de hipertrofia)
- Não completou reps por 2× → reduzir 10%
- 3 sessões sem progressão → substituir exercício
- Bodyweight: cadeia de progressão (flexão → archer → unilateral)
- Deload automático temporal: beginner=4sem, intermediate=6sem, advanced=8sem
- Persiste estado em users/{uid}/progression_state/current

---

## Motor Matemático (volumeEngine.ts)

```
volume = séries × repetições × carga
volume_alvo_semana = volume_anterior × (1 + progressão%)
carga = volume_alvo / (séries × reps)
carga arredondada para múltiplos de 2.5 kg
```

---

## Biblioteca de Exercícios (exercise_library.dart)

80+ exercícios com: padrão motor, músculos primários/secundários, restrições,
dificuldade, ambiente, cues técnicos, IDs de substituição/progressão/regressão.

Inclui exercícios de reabilitação para:
- Ombro: rotação externa/interna, Y-T-W, face pull
- Joelho: extensão terminal, step up, mini squat
- Lombar: bird dog, dead bug, hiperextensão, good morning
- Punho/Cotovelo: flexão de punho, extensão excêntrica

Mapas:
- injuryRehabExercises: lesão → IDs dos exercícios de reabilitação
- injuryAffectedMuscles: lesão → músculos/padrões afetados

---

## Tema Neo-Tactile (app_theme.dart)

| Token | Hex | Uso |
|-------|-----|-----|
| background | #0A0A0F | Fundo geral |
| surface | #181822 | Cards |
| surfaceHighlight | #232332 | Inputs |
| accent | #3B82FF | Azul primário |
| success | #22C55E | Verde |
| danger | #EF4444 | Vermelho / deload |
| textPrimary | #F3F4F6 | Texto principal |
| textSecondary | #9CA3AF | Texto auxiliar |

---

## O que já está implementado (✅)

- ✅ Firebase backend completo (rules, indexes, 4 functions, volumeEngine)
- ✅ Auth (login, cadastro, logout)
- ✅ Roteamento com GoRouter + redirect por auth
- ✅ Tema escuro global Neo-Tactile
- ✅ Dashboard com volume semanal, comparação semana anterior, volume por músculo, atalhos
- ✅ Tela de Exercícios (lista, busca, filtro, adicionar, detalhe, editar)
- ✅ ExerciseCard com GIF + placeholder por grupo muscular
- ✅ ProgressionService — sugestões de carga (aumentar peso/reps, deload, manter)
- ✅ ProgressionScreen — sugestões agrupadas por tipo
- ✅ WorkoutScreen — sessão ativa com timer, FAB, finalizar/cancelar
- ✅ WorkoutProvider — estado da sessão, integração com ProgressionEngine no finishSession
- ✅ WorkoutHistoryScreen — histórico das últimas 20 sessões
- ✅ Analytics com gráficos Syncfusion
- ✅ Sistema de PR — detecção automática, celebração animada, histórico
- ✅ Gestão de rotinas — templates A/B/C, início rápido a partir de template
- ✅ Anamnese — 4 passos: pessoal, experiência, objetivos, restrições/ambiente
- ✅ Motor de Prescrição v2 — FB/UL/PPL completo, determinístico, lesão-aware
- ✅ Biblioteca de 80+ exercícios com reabilitação
- ✅ PrescribedWorkoutScreen — exibe RIR, cadência, cues, fase DUP, aquecimento
- ✅ Motor de Progressão v2 — RIR, deload automático, plateau, bodyweight chain
- ✅ ProgressionProvider — estado global de progressão para UI
- ✅ ProgressionScreen v2 — duas abas: motor RIR (pós-sessão) + histórico; banner de ciclo, deload e info RIR
- ✅ WorkoutScreen — seletor de RIR por exercício (0–5) com código de cores; badge de aviso de lesão (contraindicados)
- ✅ Dashboard — card de fase do ciclo de periodização (acumulação/intensificação/pico/deload)
- ✅ Firestore rules — progression_state + personalRecords adicionados
- ✅ Firestore indexes — índices para generated_workouts, progression_state, exercises e personalRecords

---

## O que está pendente (⏳)

- ⏳ Notificações push (deload, inatividade, PR)
- ⏳ Website Next.js + landing page
- ⏳ Sistema de download do APK (URL real)
- ⏳ Modelo freemium / monetização
- ⏳ Rodar em produção Firebase (hoje usa emuladores)

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
