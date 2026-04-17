# BuildFit — Documentação Completa do Projeto

> **Versão:** v5.1 | **Última atualização:** 2026-04-17  
> App mobile de prescrição científica de treino com nutrição bio-adaptativa.

---

## 1. Visão Geral e Proposta de Valor

O **BuildFit** é um aplicativo completo de saúde e performance que une:

- **Prescrição inteligente de treino** — motor científico que monta planos personalizados baseados em anamnese detalhada, periodização, biomecânica e ciência do esporte (Schoenfeld, Bompa, NSCA).
- **Progressão adaptativa por RIR** — o app detecta automaticamente quando o usuário está pronto para evoluir a carga, entrar em deload ou trocar exercícios.
- **Nutrição bio-adaptativa** — módulo de gestão energética semanal (Bio-Gestão 7.0) que ajusta calorias e macros com base nos treinos realizados, usando TDEE dinâmico e orçamento semanal.
- **Digital Twin** — perfil bio-adaptativo que aprende tolerância a volume, capacidade de recuperação e aderência real do usuário ao longo do tempo.
- **Sistema Freemium** — camada Free com funcionalidades básicas e camada Pro (ativada por token ou admin) com acesso ao motor completo.
- **Landing Page** — site Next.js em Vercel com download do APK e link para o app web.

**Público-alvo:** Praticantes de musculação, atletas amadores e pessoas que buscam orientação científica de treino sem contratar um personal trainer.

---

## 2. Tech Stack Completo

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| **Mobile/App** | Flutter (Dart) | SDK ^3.11.4 |
| **Web App** | Flutter Web (compilado) | — |
| **Landing Page** | Next.js 15 (App Router) + React 19 | — |
| **Roteamento** | go_router | ^17 |
| **Estado global** | provider | ^6 |
| **Backend** | Firebase (Firestore, Auth, Functions, Storage) | — |
| **Cloud Functions** | TypeScript + Node.js ≥ 18 | — |
| **Autenticação** | Firebase Auth | ^6.3.0 |
| **Banco de dados** | Cloud Firestore | ^6.2.0 |
| **Armazenamento** | Firebase Storage | — |
| **Notificações Push** | Firebase Cloud Messaging (FCM) | ^16.1.3 |
| **Notificações Locais** | flutter_local_notifications | ^18.0.1 |
| **Gráficos** | Syncfusion Flutter Charts | ^33.1.45 |
| **Animações** | flutter_animate | ^4.5.2 |
| **Fontes** | Google Fonts (Outfit/Inter) | ^8.0.2 |
| **HTTP** | http | ^1.2.0 |
| **Datas** | intl | ^0.19.0 |
| **Deploy** | Vercel (landing + Flutter web) | — |
| **Tema** | Dark "Neo-Tactile" — `#0A0A0F` background | — |

---

## 3. Estrutura de Arquivos

```
App de calculo de carga/
│
├── firebase/                          ← Backend Firebase
│   ├── firebase.json
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── functions/src/
│       ├── index.ts                   ← 8 Cloud Functions
│       ├── volumeEngine.ts            ← motor matemático de volume
│       ├── pushNotifications.ts       ← push: PR, deload, inatividade
│       ├── proToken.ts                ← resgate de token Pro
│       ├── types.ts
│       └── seed_exercises.ts          ← popula Firestore global
│
├── website/                           ← Landing Page (Vercel)
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx                   ← hero, features, ciência, download APK
│   │   └── api/gif/route.ts           ← proxy serverless para GIFs do Firebase
│   ├── public/
│   │   ├── download/apk.apk           ← APK para download direto
│   │   └── treino/                    ← Flutter Web compilado
│   ├── next.config.ts
│   └── package.json
│
└── app/lib/                           ← Código Flutter
    ├── main.dart                      ← providers + FCM setup
    ├── firebase_options.dart
    ├── core/
    │   ├── data/
    │   │   ├── exercise_library.dart  ← 949 exercícios biomecanicamente qualificados
    │   │   └── mock_exercises.dart    ← legado
    │   ├── router/app_router.dart
    │   ├── scripts/seed_cloud.dart
    │   └── services/
    │       ├── auth_service.dart
    │       ├── notification_service.dart
    │       └── pro_service.dart
    ├── shared/
    │   ├── theme/app_theme.dart
    │   └── widgets/pro_gate_dialog.dart
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
        ├── workout/
        │   ├── workout_models.dart
        │   ├── workout_provider.dart
        │   ├── workout_screen.dart
        │   ├── workout_history_screen.dart
        │   ├── workout_profile_model.dart
        │   ├── workout_profile_provider.dart
        │   ├── workout_routine_model.dart
        │   ├── routine_service.dart
        │   ├── routine_list_screen.dart
        │   ├── routine_detail_screen.dart
        │   ├── anamnese_screen.dart
        │   ├── prescribed_workout_model.dart
        │   ├── prescribed_workout_screen.dart
        │   ├── prescription_engine.dart       ← motor v5.1 (100% esportivo)
        │   ├── sport_plan_builders.dart       ← builders esportivos
        │   ├── progression_engine.dart        ← motor de progressão v2
        │   ├── progression_provider.dart
        │   ├── exercise_rotation_manager.dart ← rotação semanal
        │   ├── session_fatigue_accumulator.dart
        │   ├── bio_adaptive_engine.dart
        │   ├── pr_model.dart
        │   ├── pr_service.dart
        │   └── pr_celebration_dialog.dart
        └── nutrition/
            ├── nutrition_profile_model.dart
            ├── meal_model.dart
            ├── nutrition_provider.dart
            ├── nutrition_engine.dart
            ├── nutrition_service.dart
            ├── nutrition_screen.dart
            ├── food_search_screen.dart
            └── nutrition_settings_screen.dart
```

---

## 4. Modelos de Dados

### 4.1 ExerciseModel — Modelo de Exercício

Cada exercício da biblioteca tem os seguintes campos:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | ID único (ex: `agachamento_livre`) |
| `name` | String | Nome em português (ex: `Agachamento Livre`) |
| `nameEn` | String | Nome em inglês (ex: `Barbell Back Squat`) |
| `primaryMuscles` | List\<String\> | Músculos primários (ex: `['quads', 'glutes']`) |
| `secondaryMuscles` | List\<String\> | Músculos sinergistas |
| `movementPattern` | String | `squat` \| `hinge` \| `push_horizontal` \| `push_vertical` \| `push_incline` \| `pull_horizontal` \| `pull_vertical` \| `carry` \| `rotation` \| `isolation` |
| `equipment` | List\<String\> | Equipamentos necessários (ex: `['barbell', 'rack']`) |
| `environment` | List\<String\> | `gym` \| `home` \| `outdoor` |
| `category` | String | `compound` \| `isolation` |
| `difficulty` | String | `beginner` \| `intermediate` \| `advanced` |
| `restrictions` | List\<String\> | Contraindicações: `knee` \| `lower_back` \| `shoulder` \| `wrist` \| `elbow` \| `hypertension` \| `hernia` |
| `repRangeMin` | int | Mínimo de repetições recomendado |
| `repRangeMax` | int | Máximo de repetições recomendado |
| `isUnilateral` | bool | Se é exercício unilateral |
| `gifUrl` | String? | URL do GIF de demonstração |
| `videoUrl` | String? | URL do vídeo de execução |
| `cues` | List\<String\> | Dicas de técnica/execução |
| `instructions` | List\<String\> | Passo a passo completo |
| `substituteIds` | List\<String\> | IDs de exercícios substitutos equivalentes |
| `progressionIds` | List\<String\> | IDs de progressões (versões mais difíceis) |
| `regressionIds` | List\<String\> | IDs de regressões (versões mais fáceis) |
| `tags` | List\<String\> | Tags livres (ex: `['hiit', 'explosivo']`) |
| `spinalLoad` | double | Carga axial lombar (0.0–1.0). Terra = 1.0 |
| `shoulderStress` | double | Estresse articular no ombro (0.0–1.0) |
| `kneeStress` | double | Estresse no joelho (0.0–1.0) |
| `cnsLoad` | double | Carga no sistema nervoso central (0.0–1.0) |
| `stabilityType` | String | `none` \| `anti_extension` \| `anti_rotation` \| `lateral` \| `scapular` |
| `lengthBias` | String | Posição de pico de tensão: `lengthened` \| `shortened` \| `mid_range` (Schoenfeld 2021) |
| `skillLevel` | int | Complexidade técnica/neural de 1 a 5 |

### 4.2 WorkoutProfile — Perfil do Usuário (Anamnese)

Salvo em `users/{uid}/profile/current`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `uid` | String | ID do usuário |
| `age` | int | Idade em anos |
| `biologicalSex` | String | `male` \| `female` |
| `weightKg` | double | Peso corporal em kg |
| `heightCm` | double | Altura em cm |
| `experienceLevel` | String | `beginner` \| `intermediate` \| `advanced` |
| `trainingAge` | int | Tempo de treino em meses |
| `bodyFatCategory` | String | `low` \| `medium` \| `high` |
| `primaryGoal` | String | `hypertrophy` \| `fat_loss` \| `strength` \| `endurance` \| `general_health` \| `athletic_performance` \| `sport_specific` \| `calisthenics` \| `functional_hiit` \| `mobility_rehab` |
| `sportSubType` | String | `run_5k` \| `run_10k` \| `run_half` \| `run_marathon` \| `mma` \| `bjj` \| `boxing` \| `soccer` \| `basketball` \| `swimming` \| `cycling` \| `agility` \| `none` |
| `trainingModality` | String | `traditional` \| `calisthenics` \| `hiit_tabata` \| `functional` \| `home_no_equip` \| `home_dumbbells` \| `home_bands` \| `kettlebell_only` \| `mobility` \| `rehab` \| `template_5x5` \| `template_gvt` \| `template_531` \| `template_phat` \| `template_phul` \| `none` |
| `availableDaysPerWeek` | int | Dias disponíveis por semana (2–7) |
| `sessionDurationMinutes` | int | Duração ideal da sessão: `30` \| `45` \| `60` \| `75` \| `90` |
| `preferredStyle` | String | `compound_focus` \| `isolation_focus` \| `circuit` \| `high_frequency` \| `moderate_volume` |
| `sleepQuality` | String | `good` \| `regular` \| `poor` |
| `stressLevel` | String | `low` \| `medium` \| `high` |
| `priorityMuscles` | List\<String\> | Grupos musculares prioritários |
| `environment` | String | `full_gym` \| `basic_gym` \| `home_dumbbell` \| `home_bodyweight` \| `outdoor` |
| `availableEquipment` | List\<String\> | Equipamentos disponíveis |
| `dislikedExercises` | List\<String\> | Exercícios que o usuário não quer |
| `favoriteExercises` | List\<String\> | Exercícios preferidos (nunca rotacionados) |
| `healthRestrictions` | List\<String\> | `knee` \| `lower_back` \| `shoulder` \| `wrist` \| `elbow` \| `hypertension` \| `hernia` |
| `currentWeek` | int | Semana atual do mesociclo |
| `exerciseRotationOffset` | int | Seed de variação para rotação de exercícios |
| `adaptive` | UserAdaptiveProfile | Sub-perfil de adaptação (Digital Twin) |
| `createdAt` | DateTime | Data de criação |
| `updatedAt` | DateTime | Última atualização |

#### 4.2.1 UserAdaptiveProfile (Digital Twin)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `volumeTolerance` | String | `high` \| `medium` \| `low` |
| `recoveryCapacity` | String | `high` \| `medium` \| `low` |
| `adherenceRate` | double | Consistência real (0.0–1.0) |
| `volumeSensitivity` | double | Quanto o usuário regride com alto volume |

### 4.3 GeneratedWorkout — Plano Gerado

Salvo em `users/{uid}/generated_workouts/current` (e múltiplos planos com IDs únicos).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | ID único do plano |
| `userId` | String | UID do dono |
| `name` | String | Nome do plano (ex: `PPL — Hipertrofia`) |
| `splitType` | String | `full_body` \| `upper_lower` \| `ppl` \| `arnold` \| etc. |
| `periodizationModel` | String | `linear` \| `dup` \| `block` |
| `sessions` | List\<PrescribedSession\> | Lista de sessões do plano |
| `mesocycleDurationWeeks` | int | Duração do mesociclo em semanas |
| `preferredStyle` | String? | Estilo preferido do usuário |
| `generatedAt` | DateTime | Data de geração |
| `isActive` | bool | Se é o plano ativo atual |

#### 4.3.1 PrescribedSession — Sessão Prescrita

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | ID da sessão (ex: `session_A`) |
| `name` | String | Nome (ex: `Empurrar — Peito e Ombros`) |
| `objective` | String | Objetivo da sessão (ex: `Hipertrofia de empurrar`) |
| `estimatedDurationMinutes` | int | Duração estimada em minutos |
| `warmupInstructions` | List\<String\> | Protocolo RAMP de aquecimento |
| `exercises` | List\<PrescribedExercise\> | Exercícios da sessão |
| `progressionNote` | String | Nota do motor sobre a progressão |
| `fatigue` | FatigueMetrics | Métricas de fadiga acumulada da sessão |

#### 4.3.2 PrescribedExercise — Exercício Prescrito

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `exercise` | ExerciseModel | Dados completos do exercício |
| `sets` | int | Número de séries |
| `repsMin` | int | Repetições mínimas |
| `repsMax` | int | Repetições máximas |
| `rir` | int | Repetições em Reserva alvo (Schoenfeld 2021) |
| `restSeconds` | int | Descanso entre séries em segundos |
| `tempo` | String | Cadência de execução (ex: `2-0-2` = concêntrica-isometrica-excêntrica) |
| `sessionCues` | List\<String\> | Dicas específicas para esta sessão |
| `progressionNote` | String | Orientação de progressão |
| `injuryNote` | String? | Alerta de segurança baseado em restrições |

#### 4.3.3 FatigueMetrics — Métricas de Fadiga

| Campo | Tipo | Thresholds |
|-------|------|-----------|
| `spinalLoad` | double | >0.85 = crítico, >0.65 = alto, >0.4 = moderado |
| `shoulderStress` | double | Igual acima |
| `kneeStress` | double | Igual acima |
| `cnsLoad` | double | Igual acima |

---

## 5. Motores e Algoritmos

### 5.1 Motor de Prescrição v5.1

**Arquivo:** `prescription_engine.dart` + `sport_plan_builders.dart`

O motor seleciona automaticamente o tipo de plano com base no `primaryGoal` e `trainingModality` do usuário:

#### Divisões suportadas (splitType):

| Tipo | Plano | Dias | Objetivo |
|------|-------|------|----------|
| **Clássico** | Full Body | 2–3 | Iniciantes / manutenção |
| **Clássico** | Upper/Lower | 4 | Força + hipertrofia |
| **Clássico** | PPL (3/5/6 dias) | 3,5,6 | Hipertrofia |
| **Clássico** | Arnold Split | 6 | Volume alto avançado |
| **Clássico** | PPL+UL Híbrido | 5 | Experiência intermediária |
| **Templates** | 5x5 | 3 | Força |
| **Templates** | GVT (10x10) | 4 | Volume extremo |
| **Templates** | 5/3/1 | 4 | Força periodizada |
| **Templates** | PHUL | 4 | Força + hipertrofia |
| **Templates** | PHAT | 5 | Performance + hipertrofia |
| **Esportivo** | Corrida (5k→42k) | 3–5 | Performance aeróbica |
| **Esportivo** | Futebol | 3–4 | Potência + agilidade |
| **Esportivo** | MMA/BJJ/Boxe | 3–5 | Força funcional + condicionamento |
| **Esportivo** | Natação | 3–4 | Core + mobilidade |
| **Esportivo** | Ciclismo | 3–4 | Potência de membros inferiores |
| **Modalidade** | Calistenia | 3–5 | Skills + Straight Weight |
| **Modalidade** | HIIT (Tabata/EMOM) | 3–5 | Condicionamento |
| **Modalidade** | Funcional | 3–4 | Padrões multiarticulares |
| **Saúde** | Mobilidade | 2–3 | Longevidade |
| **Saúde** | Reabilitação | 2–3 | Ombro, Joelho, Lombar, etc. |
| **Saúde** | Terceira Idade | 2–3 | Sarcopenia + equilíbrio |

#### Recursos do Motor v5.1:

- **Adaptação Anatômica (Bompa):** Iniciantes têm RIR elevado (3–4) e reps 12–15 para fortalecer ligamentos antes de usar cargas neurais.
- **Aquecimento RAMP (NSCA):** Protocolo estratificado com *Raise* (ativação cardiovascular), *Activate/Mobilize* (preparação articular) e *Potentiate* (ativação neuromuscular com explosão).
- **DUP Avançada:** Ondulação Diária de Intensidade — o motor alterna entre dias de força (5–7 reps, RIR 1–2), hipertrofia (8–12 reps, RIR 2–3) e volume (13–20 reps, RIR 3–4).
- **Filtro de Lesões:** Exercícios conflitantes com `healthRestrictions` são automaticamente removidos e substituídos.
- **Seletor de Ambiente:** Planos esportivos cruzam com `environment = home` e substituem equipamentos industriais por bodyweight/dumbbells/bands.
- **Length Bias (Schoenfeld):** Alterna entre exercícios em posição alongada (`lengthened`) e encurtada (`shortened`) para máxima hipertrofia miofibrilar.
- **Separação Explosivo vs Força Lenta (NSCA):** Dias explicitamente marcados como "explosivos" com instrução de velocidade concêntrica máxima.

### 5.2 Motor de Progressão v2

**Arquivo:** `progression_engine.dart`

Tabela de decisão baseada em RIR (Repetições em Reserva):

| RIR reportado | Decisão | Ação |
|--------------|---------|------|
| ≥ 3 | Aumentar carga | +2,5kg (MMSS) / +5kg (MMII) |
| 1–2 | Consolidar | Zona ideal — manter carga |
| Não completou reps (2×) | Reduzir | −10% da carga |
| 3 sessões sem progresso | Trocar exercício | Seleciona substituto |
| Bodyweight estagnado | Progredir cadeia | Flexão → Archer → Unilateral |
| Beginner: 4 sem sem deload | Deload automático | −40% volume por 1 semana |
| Intermediate: 6 sem | Deload automático | — |
| Advanced: 8 sem | Deload automático | — |

**Persistência:** `users/{uid}/progression_state/current`

### 5.3 Exercise Rotation Manager

**Arquivo:** `exercise_rotation_manager.dart`

- A cada 2 semanas, 1–2 exercícios por grupo muscular são trocados por equivalentes do mesmo `movementPattern`.
- **Nunca troca:** exercícios `favoriteExercises` do usuário.
- **Nunca inclui:** exercícios `dislikedExercises`.
- **Base científica:** Schoenfeld IUSCA 2021 + Bompa Periodization.

### 5.4 Session Fatigue Accumulator

**Arquivo:** `session_fatigue_accumulator.dart`

Rastreia fadiga multiarticular **durante** a montagem da sessão:

| Eixo | Limite máximo | Critical threshold |
|------|--------------|-------------------|
| `spinalLoadAccumulated` | 3.0 | 2.4 (80%) |
| `shoulderStressAccumulated` | 3.5 | 2.8 (80%) |
| `kneeStressAccumulated` | 4.0 | 3.2 (80%) |
| `cnsLoadAccumulated` | 3.0 | 2.4 (80%) |

`canAdd(exercise, sets)` verifica se adicionar o exercício estouraria os limites antes de incluir na sessão.

### 5.5 Motor Matemático de Volume (Cloud Function)

**Arquivo:** `volumeEngine.ts`

```
volume = séries × repetições × carga
volume_alvo_semana = volume_anterior × (1 + progressão%)
carga = volume_alvo / (séries × reps)
carga arredondada para múltiplos de 2.5 kg
```

### 5.6 Bio-Gestão 7.0 — Nutrição Adaptativa

**Arquivo:** `nutrition_engine.dart`

O sistema trata a nutrição como **orçamento energético semanal**, não metas diárias fixas.

#### Cálculo do TDEE Dinâmico (Mifflin-St Jeor):

```
TMB (homem) = 10×peso + 6.25×altura − 5×idade + 5
TMB (mulher) = 10×peso + 6.25×altura − 5×idade − 161
TDEE = TMB × fator_atividade
```

#### Orçamento Semanal:

- `weeklyBudgetKcal = TDEE × 7`
- **Dias de treino (Alta Demanda):** `1.10 × calorias_diárias` (+10%, foco em carboidratos)
- **Dias de descanso:** `0.85 × calorias_diárias` (−15%)
- A soma dos 7 dias é calibrada para bater exatamente o `weeklyBudgetKcal`.

#### Motor de Compensação:

1. Detecta desvio: `Consumo Real − Meta Diária`
2. Calcula dias restantes até domingo
3. Distribui excesso pelos dias restantes
4. **Trava de segurança:** Calorias nunca caem abaixo da TMB
5. **Prioridade de corte:** Carboidratos primeiro (proteína e gordura protegidas)

#### Indicadores de Saúde Metabólica:

| Indicador | Campo | Trigger |
|-----------|-------|---------|
| Aderência | `adherenceScore` | < 0.7 = estratégia muito rígida |
| Fadiga Nutricional | `nutritionalFatigueLevel` | Déficit > 6 semanas = sugestão de refeed |
| Bônus Pós-Treino | — | +100 a +250 kcal/dia após sessão registrada |
| Carb Cycling | — | High carb em dias de treino, low carb em descanso |

---

## 6. Telas e Navegação

### 6.1 Rotas (go_router)

| Rota | Tela | Acesso |
|------|------|--------|
| `/login` | LoginScreen | Free |
| `/register` | RegisterScreen | Free |
| `/dashboard` | DashboardScreen | Free |
| `/exercises` | ExerciseScreen | Free |
| `/exercises/add` | AddExerciseScreen | Free |
| `/exercises/:id` | ExerciseDetailScreen | Free |
| `/workout` | WorkoutScreen | Free |
| `/workout/history` | WorkoutHistoryScreen | **Pro** |
| `/routines` | RoutineListScreen | Free |
| `/routines/detail` | RoutineDetailScreen | Free |
| `/anamnese` | AnamneseScreen | Free |
| `/prescribed` | PrescribedWorkoutScreen | **Pro** |
| `/progression` | ProgressionScreen | **Pro** |
| `/analytics` | AnalyticsScreen | **Pro** |
| `/nutrition` | NutritionScreen | **Pro** |
| `/nutrition/search` | FoodSearchScreen | **Pro** |
| `/nutrition/settings` | NutritionSettingsScreen | **Pro** |
| `/profile` | ProfileScreen | Free |

### 6.2 Fluxo Principal do Usuário

```
Login/Cadastro
    ↓
Dashboard (volume semanal, atalhos, comparativo)
    ↓
Anamnese (4 passos) → Motor de Prescrição → Plano Gerado
    ↓
PrescribedWorkoutScreen → Selecionar Sessão → WorkoutScreen (sessão ativa)
    ↓
Registrar séries + RIR → Finalizar → Motor de Progressão → Próxima sessão ajustada
```

### 6.3 Funcionalidades por Tela

#### Dashboard
- Volume semanal total (kg)
- Comparação com semana anterior (%)
- Breakdown por grupo muscular
- Atalhos rápidos para todas as seções

#### WorkoutScreen (Sessão Ativa)
- Timer de sessão em tempo real
- Lista de exercícios com sets editáveis
- Selector de RIR (0–5) com feedback textual e colorido
- Botão "Tutorial do Exercício" → abre modal com GIF animado + instruções + dicas + protocolo de aquecimento
- Badge de aviso de lesão quando exercício conflita com restrições
- Troca de exercício em tempo real (substitutos diretos + fallback por padrão muscular)
- Adição de séries + séries de aquecimento
- Volume total calculado em tempo real

#### PrescribedWorkoutScreen (Meus Treinos)
- Lista de todos os planos gerados
- Cards com: nome do plano, divisão, período, estilo
- Botão "Ativar Plano" + "Ver Sessões"
- Badge "PLANO ATIVO" no plano atual

#### ProgressionScreen
- Aba 1: Sugestões do Motor RIR (carga recomendada por exercício)
- Aba 2: Histórico de progressão

#### AnalyticsScreen
- Gráficos Syncfusion de volume por semana
- Volume por grupao muscular
- Evolução de cargas por exercício

#### NutritionScreen
- Dashboard nutricional (gráfico de rosca de macros)
- Timeline semanal interativa (Seg–Dom com metas por dia)
- Log de refeições do dia
- Botão para busca de alimentos
- Score de aderência e aviso de fadiga nutricional

---

## 7. Estrutura Firestore

```
users/{uid}
  ├── profile/current                    ← WorkoutProfile (anamnese)
  ├── generated_workouts/{planId}        ← GeneratedWorkout (planos gerados)
  │     isActive: boolean                ← controla qual plano está ativo
  ├── workouts/{wId}                     ← Sessões realizadas
  │     date, weekNumber, totalVolume, exerciseCount
  │     exercises: [{exerciseId, exerciseName, muscleGroup,
  │                  sets:[{reps, weight, volume}], volume}]
  ├── exercises/{exId}                   ← Exercícios personalizados do usuário
  ├── progression_state/current          ← ProgressionState (RIR, deload, plateaus)
  │     phase: 'normal' | 'deload'
  │     currentWeek: int
  │     exerciseStates: {exId: {rir, lastWeight, plateauCount}}
  ├── personalRecords/{exId}             ← PRs por exercício
  │     exerciseId, exerciseName, weight, reps, achievedAt
  ├── progressionWeeks/{pwId}            ← Histórico semanal de progressão
  ├── volumeHistory/{vhId}               ← Escrito apenas por Cloud Functions
  ├── suggestedProgressions/{spId}       ← Sugestões do motor
  ├── nutrition/settings                 ← NutritionProfile (metas, macros, toggles)
  └── nutrition/logs/{yyyy-mm-dd}
        ├── meals/{mId}                  ← MealEntry (refeições registradas)
        └── summary                      ← Agregado diário (kcal, P, C, G)

  isPro: boolean                         ← Status Pro do usuário
  proActivatedAt: timestamp
  proTokenUsed: string
  fcmToken: string                       ← Token FCM para push

config/apkVersion                        ← Versão atual do APK
exercises/{exId}                         ← Biblioteca global (949 exercícios)
proTokens/{code}                         ← Tokens de liberação Pro
  code: string
  maxRedemptions: number                 ← -1 = ilimitado
  currentRedemptions: number
  createdAt: timestamp
  expiresAt?: timestamp
  label?: string
  └── redemptions/{uid}
        userId: string
        redeemedAt: timestamp
```

---

## 8. Cloud Functions (8 funções)

| Nº | Nome | Tipo | Gatilho | Ação |
|----|------|------|---------|------|
| 1 | `onWorkoutExerciseSave` | Trigger | Firestore `workouts/{wId}` write | Valida/corrige volume, agrega `volumeHistory` |
| 2 | `generateProgressionSuggestions` | Callable | Chamada pelo app | Calcula sugestões de progressão de carga |
| 3 | `calculatePeriodizationPlan` | Callable | Chamada pelo app | Gera plano de periodização completo |
| 4 | `getApkVersion` | Callable | Chamada pelo app | Retorna metadados do APK atual |
| 5 | `onPersonalRecordCreated` | Trigger | `users/{uid}/personalRecords/{prId}` | Envia push de celebração de PR |
| 6 | `onDeloadActivated` | Trigger | `progression_state` phase → `deload` | Envia push avisando sobre deload |
| 7 | `notifyInactiveUsers` | Scheduled | Diário às 9h BRT | Push para quem não treina há 7+ dias |
| 8 | `redeemProToken` | Callable | Chamada pelo app | Valida e resgata código Pro (verifica limite, expiração, registra resgate) |

---

## 9. Sistema Freemium (Free vs Pro)

### Controle de Acesso
- Campo `users/{uid}.isPro` (boolean) no Firestore
- `ProService` verifica esse campo antes de liberar funcionalidades
- `ProGate.show(context)` abre dialog com lista de features Pro + campo de resgate

### Ativação Pro (3 formas)
1. **Token de resgate** → usuário insere código → Cloud Function `redeemProToken` valida
2. **Admin** → setar `users/{uid}.isPro = true` diretamente no Firestore
3. **ProService.setProStatus(true)** → apenas para testes (remover em produção)

### Features FREE vs PRO

| Feature | Free | Pro |
|---------|------|-----|
| Login/Cadastro | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| Lista de exercícios | ✅ | ✅ |
| Anamnese | ✅ | ✅ |
| Sessão de treino básica | ✅ | ✅ |
| Prescrição inteligente | ❌ | ✅ |
| Analytics com gráficos | ❌ | ✅ |
| Progressão RIR | ❌ | ✅ |
| Records pessoais (PR) | ❌ | ✅ |
| Rotação semanal de exercícios | ❌ | ✅ |
| Deload automático | ❌ | ✅ |
| Histórico de treinos | ❌ | ✅ |
| Nutrição Bio-Adaptativa | ❌ | ✅ |

---

## 10. Notificações Push

### Arquitetura Mista (Local + FCM)

| Tipo | Canal | Gatilho |
|------|-------|---------|
| Local | `flutter_local_notifications` | `NotificationService.showLocalNotification()` |
| Push remoto | Firebase Cloud Messaging | Cloud Functions (triggers + cron) |
| Inatividade local | `scheduleInactivityReminder` | Startup do app |
| PR remoto | `onPersonalRecordCreated` | Novo PR salvo no Firestore |
| Deload remoto | `onDeloadActivated` | Fase de progressão muda para `deload` |
| Inatividade remota | `notifyInactiveUsers` | Agendada diariamente às 9h BRT |

> **Nota:** FCM não roda em web — todas as chamadas `FirebaseMessaging` têm bypass `if (!kIsWeb)`.

---

## 11. Sistema de GIFs de Exercícios

### Arquitetura atual

- **GIFs armazenados no Firebase Storage** (`gs://appcalculotreino-51f23.firebasestorage.app`)
- **Problema CORS no Web:** Navegador bloqueia requisições diretas para o Storage
- **Solução:** Proxy serverless via Next.js API Route (`website/app/api/gif/route.ts`)
  - Flutter solicita: `https://[dominio]/api/gif?name=[nome_exercicio]`
  - Vercel executa a função, busca o arquivo no Storage e retorna com header `Access-Control-Allow-Origin: *`
- **Android/iOS:** Acessa o Firebase Storage diretamente (sem CORS)
- **Renderização:** `Image.network` (suporte nativo a GIF animado no Flutter)

> **Importante:** `CachedNetworkImage` NÃO anima GIFs — exibe apenas o 1º frame estático. Sempre usar `Image.network` com `gaplessPlayback: true`.

---

## 12. Tema Visual (Neo-Tactile Dark)

| Token | Hex | Uso |
|-------|-----|-----|
| `background` | `#0A0A0F` | Fundo geral |
| `surface` | `#181822` | Cards e containers |
| `surfaceHighlight` | `#232332` | Inputs e botões secundários |
| `accent` | `#3B82FF` | Azul primário — CTAs e destaques |
| `accentVariant` | `#1E5AD6` | Azul escuro |
| `success` | `#22C55E` | Verde — progresso e sucesso |
| `danger` | `#EF4444` | Vermelho — deload e erros |
| `textPrimary` | `#F3F4F6` | Texto principal |
| `textSecondary` | `#9CA3AF` | Texto auxiliar e labels |

**Fonte:** Google Fonts — **Outfit** (títulos e destaques) + **Inter** (corpo de texto)

---

## 13. Landing Page (Next.js)

**URL:** https://buildfit-nine.vercel.app/

**Seções:**
1. **Hero** — headline + CTA "Baixar APK" + "Entrar no App"
2. **Features** — 6 cards com funcionalidades principais
3. **Ciência** — 4 referências científicas (Schoenfeld, Bompa, NSCA, Mifflin-St Jeor)
4. **Download APK** — botão com download direto do `.apk`

**Rotas importantes:**
- `/` → Landing page
- `/app` → Redireciona para o Flutter Web (`/treino/`)
- `/download/apk` → APK direto (via `public/download/apk.apk`)
- `/api/gif?name=[nome]` → Proxy serverless para GIFs do Firebase

---

## 14. Deploy e Infraestrutura

### Vercel (projeto: `buildfit-nine`)
- **Build Command:** `cd website && npm install && npm run build`
- **Output Directory:** `website/.next/standalone`
- **Root Directory:** vazio (vercel.json cuida do resto)
- **Auto-deploy:** Ativado — todo `git push main` dispara rebuild

### Firebase
- **Projeto:** `appcalculotreino-51f23`
- **Bucket Storage:** `gs://appcalculotreino-51f23.firebasestorage.app`
- **Rules Storage:** Leitura pública (`allow read: if true`)
- **Functions:** Emulador local para desenvolvimento, produção no Firebase Console

### Flutter Web
- Compilado com `flutter build web --no-tree-shake-icons`
- Output: `app/build/web/`
- Copiado para `website/public/treino/` antes do git push

---

## 15. Padrões de Código

- Sem lógica de negócio nas telas — tudo via Provider ou Service
- Providers estendem `ChangeNotifier`
- `StreamSubscription` sempre cancelado no `dispose()`
- UIDs sempre de `FirebaseAuth.instance.currentUser?.uid`
- Queries Firestore usando índices compostos existentes
- Erros em português amigável ao usuário
- `withValues(alpha:)` em vez de `withOpacity()` (deprecado)
- FCM: `fcmToken` armazenado em `users/{uid}.fcmToken`
- FCM bypass em web: `if (!kIsWeb)` antes de qualquer `FirebaseMessaging`
- `<receiver>` tags sempre dentro de `<application>` no `AndroidManifest.xml`
- Features PRO: gate via `ProGate.show(context)` + `ProService.isPro()`
- GIFs: sempre `Image.network` com `gaplessPlayback: true` (nunca `CachedNetworkImage` para GIF)

---

## 16. Pendências e Próximos Passos

| Item | Prioridade | Status |
|------|-----------|--------|
| Integração Stripe (pagamentos reais Pro) | Alta | ⏳ Pendente |
| Criar tokens Pro iniciais para beta testers | Alta | ⏳ Pendente |
| Deploy Firebase Functions em produção | Média | ⏳ Pendente |
| Remover botão "Ativar Pro (teste local)" antes da produção | Alta | ⏳ Pendente |
| APK de release estável para distribuição | Média | ⏳ Pendente |

---

*Documento gerado em 2026-04-17 com base no código-fonte e histórico de desenvolvimento do projeto.*
