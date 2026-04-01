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
│       ├── index.ts          ← 4 Cloud Functions
│       ├── volumeEngine.ts   ← motor matemático
│       └── types.ts
│
└── app/lib/
    ├── main.dart
    ├── firebase_options.dart
    ├── core/
    │   ├── router/app_router.dart
    │   └── services/auth_service.dart
    ├── shared/theme/app_theme.dart
    └── features/
        ├── auth/
        │   ├── login_screen.dart
        │   └── register_screen.dart
        ├── dashboard/
        │   └── dashboard_screen.dart
        ├── exercises/
        │   ├── exercise_provider.dart    ← ExerciseModel + ExerciseProvider
        │   ├── exercise_screen.dart
        │   ├── exercise_card.dart
        │   ├── exercise_detail_screen.dart
        │   ├── add_exercise_screen.dart
        │   ├── progression_screen.dart
        │   └── progression_service.dart
        ├── analytics/
        │   ├── analytics_service.dart
        │   └── analytics_screen.dart
        └── workout/
            ├── workout_models.dart
            ├── workout_provider.dart     ← integra PrService no finishSession()
            ├── workout_screen.dart        ← didChangeDependencies escuta newPrs
            ├── workout_history_screen.dart
            ├── workout_routine_model.dart
            ├── routine_service.dart
            ├── routine_list_screen.dart
            ├── routine_detail_screen.dart
            ├── pr_model.dart              ← PersonalRecord + PrAchievement
            ├── pr_service.dart            ← lê/salva PRs no Firestore (batch)
            └── pr_celebration_dialog.dart ← dialog animado de celebração
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

---

## Firestore — estrutura de dados

```
users/{uid}
  ├── exercises/{exId}
  │     name, muscleGroup, equipment, seriesDefault, repMin, repMax, gifUrl?
  ├── workouts/{wId}
  │     date, weekNumber, totalVolume, exerciseCount
  │     exercises: [ { exerciseId, exerciseName, muscleGroup, sets: [{reps, weight, volume}], volume } ]
  ├── personalRecords/{exId}
  ├── progressionWeeks/{pwId}
  ├── volumeHistory/{vhId}   ← só Cloud Functions escrevem
  └── suggestedProgressions/{spId}   ← só Cloud Functions escrevem

config/apkVersion
```

---

## Cloud Functions implementadas

1. `onWorkoutExerciseSave` — trigger Firestore, valida e corrige volume, agrega no volumeHistory
2. `generateProgressionSuggestions` — callable, gera sugestões de progressão
3. `calculatePeriodizationPlan` — callable, calcula plano de periodização
4. `getApkVersion` — callable, retorna metadados do APK

---

## Motor matemático (volumeEngine.ts)

```
volume = séries × repetições × carga
volume_alvo_semana = volume_anterior × (1 + progressão%)
carga = volume_alvo / (séries × reps)
carga arredondada para múltiplos de 2.5 kg
```

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

## O que já está implementado (✅ completo)

- ✅ Firebase backend completo (rules, indexes, 4 functions, volumeEngine)
- ✅ Auth (login, cadastro, logout)
- ✅ Roteamento com GoRouter + redirect por auth
- ✅ Tema escuro global
- ✅ Dashboard com volume semanal, comparação com semana anterior, volume por músculo, atalhos
- ✅ Tela de Exercícios (lista, busca, filtro por grupo muscular, adicionar, detalhe, editar)
- ✅ ExerciseCard com GIF via CachedNetworkImage + placeholder por grupo muscular
- ✅ ProgressionService — lógica de sugestão de carga (aumentar peso/reps, deload, manter)
- ✅ ProgressionScreen — tela de sugestões de progressão agrupadas por tipo
- ✅ WorkoutScreen — sessão ativa com timer, FAB para adicionar exercício, finalizar/cancelar
- ✅ WorkoutProvider — estado da sessão, adicionar/remover exercício, editar séries, salvar
- ✅ WorkoutHistoryScreen — histórico das últimas 20 sessões com ExpansionTile
- ✅ AnalyticsScreen e AnalyticsService — gráficos Syncfusion (volume semanal, progressão de carga máx/média e volume por músculo com comparativo temporal)
- ✅ **Sistema de PR (Personal Records):** Detecção automática de recordes (carga, reps, volume) com animação de celebração (`PrCelebrationDialog`).
- ✅ **Gestão de Treinos (Treinos Montados):**
    - **Templates de Treino:** Criação de rotinas personalizadas (ex: Treino A, B, C) com nome e descrição.
    - **Montagem de Treino:** Adição de exercícios específicos a cada rotina com definição de séries e repetições padrão.
    - **Início Rápido:** Capacidade de iniciar uma sessão de treino a partir de um template, carregando automaticamente os exercícios configurados.
- ✅ **Integração:** `WorkoutProvider` gerencia tanto sessões livres quanto sessões baseadas em rotinas.
- ✅ PrModel e PrService — gerenciamento de recordes no Firestore com persistência e histórico
- ✅ PrCelebrationDialog — interface animada com troféu e badges para celebrar novas conquistas
- ✅ Detalhamento de PR — visualização de recordes específicos dentro da tela de detalhes de cada exercício

---

## O que está pendente (⏳)

- ⏳ Tela de Sugestões de Progressão conectada às Cloud Functions
- ⏳ Sistema de onboarding com questionário
- ⏳ Geração automática de treino baseada no questionário
- ⏳ Sistema adaptativo
- ⏳ Plano de 12 semanas automático
- ⏳ Sistema de lesões
- ⏳ Notificações
- ⏳ Website Next.js + landing page
- ⏳ Sistema de download do APK
- ⏳ Modelo freemium / monetização

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

---

## MCP configurado (Claude Desktop)

O arquivo de configuração está em:
```
C:\Users\Felipe\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json
```

Conteúdo:
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

Para verificar se está funcionando: abre o Claude Desktop, nova conversa, e digita:
"Liste os arquivos em D:\App de calculo de carga"

---

## Próximos passos sugeridos (por prioridade)

1. **Onboarding** — questionário inicial (objetivo, nível, dias, equipamentos) + geração automática de plano de treino
2. **Progressão via Cloud Functions** — conectar ProgressionScreen à função `generateProgressionSuggestions`
3. **Sistema de lesões** — ajustar exercícios automaticamente
4. **Website Next.js** — landing page + download do APK

---

## Padrões de código do projeto

- Sem lógica de negócio nas telas — tudo via Provider ou Service
- Providers estendem ChangeNotifier
- StreamSubscription sempre cancelado no dispose()
- UIDs sempre de FirebaseAuth.instance.currentUser?.uid
- Queries Firestore usando índices compostos existentes
- Erros em português amigável
- withValues(alpha:) em vez de withOpacity() (já corrigido)
