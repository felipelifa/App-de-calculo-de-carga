# 🏋️ BuildFit — Roadmap de Melhorias

> Baseado no prompt completo de melhorias v1.0 | Abril 2026

---

## ✅ Sprint 1 — Esta semana (IMPLEMENTAR AGORA)

| # | Item | Arquivo(s) | Status |
|---|------|-----------|--------|
| 1.1 | **Tela Perfil de Atleta** pós-anamnese | `athlete_profile_screen.dart` + `app_router.dart` + `anamnese_screen.dart` | ✅ Feito |
| 1.2 | **Coach Explainer** — IA local que explica cada decisão | `coach_explainer_service.dart` + `progression_screen.dart` + `progression_engine.dart` | ✅ Feito |
| 1.3 | **Plano de Deload Prescrito** | `deload_screen.dart` + `prescription_engine.dart` | ✅ Feito |
| 4.1 | Aplicar migrations e políticas no Supabase | `supabase_schema.sql`, `fix_rls_policies.sql` | ✅ Fluxo atual |

---

## ✅ Sprint 2 — Concluída com sucesso

| # | Item | Arquivo(s) | Status |
|---|------|-----------|--------|
| 2.1 | **Calendário semanal visual** no Dashboard | `dashboard_screen.dart` | ✅ Feito |
| 2.2 | **Barras de fadiga** na WorkoutScreen em tempo real | `workout_screen.dart` + `workout_provider.dart` | ✅ Feito |
| 2.3 | **Tela de Warm-up** dedicada antes do treino | `warmup_screen.dart` + `prescribed_workout_screen.dart` | ✅ Feito |
| 5.1 | **Timer inteligente** por fase DUP | `workout_screen.dart` | ✅ Feito |

---

## 📅 Sprint 3 — Em Andamento

| # | Item | Status |
|---|------|--------|
| 3.1 | Sistema de **Rank de Atleta** (Novato → Lenda) | ⏳ Pendente |
| 3.2 | **DUP visível** ao usuário na PrescribedWorkoutScreen | ✅ Feito |
| 3.x | **Stripe** — pagamentos reais Pro | 🔴 Fora de escopo |
| 5.2 | **Analytics** de volume por músculo melhorado | ⏳ Pendente |

---

## 🚀 Sprint 4 — 3+ meses

| # | Item | Status |
|---|------|--------|
| 3.3 | Técnicas avançadas (Drop Set, Rest-Pause, Cluster) | ⏳ Pendente |
| 3.4 | Progressão bodyweight completa (cadeia Push/Pull/Squat) | ⏳ Pendente |
| 5.3 | Tela de exercício com histórico de carga + badges | ⏳ Pendente |

---

## 📐 Regras do Motor (não violar)

1. Nunca aumentar volume **E** carga na mesma semana
2. Deload: Iniciante=4sem | Intermediário=6sem | Avançado=8sem
3. Ordem dos exercícios: Composto pesado → Composto auxiliar → Isolamento
4. Lengthened bias **antes** de shortened bias no mesmo músculo
5. Sem 2 exercícios de alto `spinalLoad` consecutivos no mesmo treino
6. RIR alvo: Iniciante 3-4 | Intermediário 1-2 | Avançado 0-1
7. Volume mínimo: 10 séries/músculo/semana para manter massa
8. Rotação a cada 2 semanas (nunca mexer nos favoritos)
9. Plateau (3 sessões) = trocar exercício, não só carga
10. O motor **explica cada decisão** em linguagem simples

---

# 🎯 HANDOFF PARA A PRÓXIMA SESSÃO (INSTRUÇÕES PARA O PRÓXIMO CHAT)

> **Caro Engenheiro/IA que assumir esta continuação:**
> Nós finalizamos com sucesso as Sprints 1 e 2. Sua prioridade absoluta e exclusiva para o início da próxima sessão é implementar os itens **3.1 (Sistema de Rank)** e **5.2 (Analytics de Volume)** da Sprint 3.
> Siga **EXTRITAMENTE** as especificações arquiteturais abaixo:

### 1. Implementação do Sistema de Rank de Atleta (3.1)
**Conceito:** Cada kg de carga total deslocado na sessão (Volume) = 1 XP. O atleta sobe de ligas conforme acumula volume ao longo das semanas.

**Passo a Passo Técnico:**
1. **Modelagem:** Editar `WorkoutProfileModel` (em `lib/features/workout/workout_profile_model.dart`) para incluir:
   - `totalXp` (double, default 0)
   - `currentRank` (String, default 'Iniciante')
   - Garantir que `toMap()` e `fromMap()` salvem esses dados no Firestore.
2. **Motor de XP (Service/Provider):** 
   - Criar uma constante global ou classe utilitária `RankEngine` que mapeia os limites (Tiers):
     - `Ferro`: 0 XP
     - `Bronze`: 50.000 XP
     - `Prata`: 150.000 XP
     - `Ouro`: 350.000 XP
     - `Platina`: 750.000 XP
     - `Diamante`: 1.500.000 XP
     - `Lenda`: 3.000.000+ XP
   - Deve haver um método `getNextRankThreshold(currentXp)` para calcular quanto falta.
3. **Injeção de XP pós-Treino:**
   - Em `workout_provider.dart`, no método `finishWorkout()`, pegar o `currentTotalVolume` (que já existe e soma Sets * Reps * Peso) e adicionar ao `totalXp` do `WorkoutProfile`.
   - Calcular se houve *Level Up*.
4. **UI/UX Gamificada (Dashboard):**
   - Na `DashboardScreen` (ou na `ProfileScreen`), renderizar uma "Progress Bar" Neon.
   - Mostrar o rank atual com um ícone visual (ex: 👑 Ouro, 💎 Diamante) e a quantidade de XP restante para o próximo nível.
5. **Feedback Imediato (Workout Screen):**
   - Modificar o dialog/animação de "Treino Concluído" para exibir o ganho de XP: *"+ 12.450 XP Ganhos Hoje!"*

### 2. Analytics de Volume por Músculo (5.2)
**Conceito:** O atleta precisa ver se está treinando mais peito do que costas. Mostrar um gráfico de pizza/radar detalhado.

**Passo a Passo Técnico:**
1. **Extração de Dados:**
   - No `WorkoutProfileProvider` ou `AnalyticsService`, criar um getter/função que itere sobre o `workoutHistory` (histórico de treinos da semana/mês).
   - Para cada `Session` concluída, somar o volume de cada `WorkoutSet` e agrupar pela string do músculo primário (`exercise.primaryMuscle`).
   - Retornar um `Map<String, double>` (Ex: `{'Peito': 12000, 'Costas': 9500, 'Quadríceps': 15000}`).
2. **Renderização Visual (UI):**
   - Na aba/tela de Analytics, usar o pacote `syncfusion_flutter_charts` (já instalado e estável no Web).
   - Implementar um `SfCircularChart` (Gráfico de Rosca/Doughnut) ou `SfRadarChart` com a paleta de cores Neon Dark do app.
   - Listar abaixo do gráfico as porcentagens de distribuição. 
   - **Detalhe UI:** O fundo deve ser `#161616` e as bordas sutis com `Colors.white10`.
