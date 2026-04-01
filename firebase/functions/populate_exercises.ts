import * as admin from 'firebase-admin';

// ─────────────────────────────────────────────
// Script para popular banco global de exercícios
// ─────────────────────────────────────────────

const exercises = [
  // PEITO
  {
    id: 'supino_reto_barra',
    name: 'Supino Reto com Barra',
    nameEn: 'Barbell Bench Press',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['triceps', 'shoulders'],
    movementPattern: 'push_horizontal',
    equipment: ['barbell', 'bench'],
    environment: ['full_gym', 'basic_gym'],
    category: 'compound',
    difficulty: 'intermediate',
    restrictions: ['shoulder', 'wrist'],
    repRangeMin: 4,
    repRangeMax: 12,
    isUnilateral: false,
    gifUrl: 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2ZqNWQ5Ym55dmZqNWQ5Ym55dmZqNWQ5Ym55dmZqNWQ5Ym55dmZqJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKVUn7iM8FMEU24/giphy.gif',
    cues: [
      'Escápulas retraídas e deprimidas',
      'Cotovelos a 45–75° do tronco',
      'Barra desce ao esterno',
      'Pés firmes no chão'
    ],
    substituteIds: ['supino_halter', 'supino_maquina'],
    progressionIds: ['supino_pausa'],
    regressionIds: ['supino_halter', 'flexao_normal'],
    tags: ['chest_compound', 'strength_focus'],
  },
  {
    id: 'push_up',
    name: 'Flexão de Braços',
    nameEn: 'Push-up',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['triceps', 'shoulders', 'core'],
    movementPattern: 'push_horizontal',
    equipment: ['bodyweight'],
    environment: ['full_gym', 'basic_gym', 'home_bodyweight', 'outdoor'],
    category: 'compound',
    difficulty: 'beginner',
    restrictions: ['wrist'],
    repRangeMin: 10,
    repRangeMax: 30,
    isUnilateral: false,
    gifUrl: 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2ZqNWQ5Ym55dmZqNWQ5Ym55dmZqNWQ5Ym55dmZqNWQ5Ym55dmZqJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKVUn7iM8FMEU24/giphy.gif',
    cues: [
      'Corpo reto como uma prancha',
      'Mãos sob os ombros',
      'Peito quase toca o chão'
    ],
    substituteIds: ['flexao_joelhos'],
    progressionIds: ['flexao_arqueiro', 'flexao_diamante'],
    regressionIds: ['flexao_joelhos'],
    tags: ['bodyweight', 'beginner_friendly'],
  },
  // COSTAS
  {
    id: 'pull_up',
    name: 'Barra Fixa Pronada',
    nameEn: 'Pull-up',
    primaryMuscles: ['back'],
    secondaryMuscles: ['biceps', 'shoulders'],
    movementPattern: 'pull_vertical',
    equipment: ['pull_up_bar'],
    environment: ['full_gym', 'basic_gym', 'outdoor'],
    category: 'compound',
    difficulty: 'advanced',
    restrictions: ['shoulder', 'elbow'],
    repRangeMin: 5,
    repRangeMax: 15,
    isUnilateral: false,
    gifUrl: '',
    cues: [
      'Puxe o peito em direção à barra',
      'Controle a descida',
      'Não balance o corpo'
    ],
    substituteIds: ['pulldown_frente', 'remada_invertida'],
    progressionIds: ['muscle_up'],
    regressionIds: ['chin_up', 'pulldown_frente'],
    tags: ['back_compound', 'pull_power'],
  },
  // QUADRÍCEPS
  {
    id: 'squat_barbell',
    name: 'Agachamento Livre Barra',
    nameEn: 'Barbell Back Squat',
    primaryMuscles: ['quads'],
    secondaryMuscles: ['glutes', 'lower_back', 'hamstrings'],
    movementPattern: 'squat',
    equipment: ['barbell'],
    environment: ['full_gym'],
    category: 'compound',
    difficulty: 'advanced',
    restrictions: ['knee', 'lower_back'],
    repRangeMin: 5,
    repRangeMax: 12,
    isUnilateral: false,
    gifUrl: '',
    cues: [
      'Mantenha o peito alto',
      'Agache até as coxas ficarem paralelas ao chão',
      'Empurre pelos calcanhares'
    ],
    substituteIds: ['leg_press', 'goblet_squat'],
    progressionIds: ['squat_pausa'],
    regressionIds: ['goblet_squat', 'air_squat'],
    tags: ['quads_compound', 'leg_power'],
  },
  {
    id: 'air_squat',
    name: 'Agachamento Livre (Peso Corporal)',
    nameEn: 'Air Squat',
    primaryMuscles: ['quads'],
    secondaryMuscles: ['glutes', 'hamstrings'],
    movementPattern: 'squat',
    equipment: ['bodyweight'],
    environment: ['full_gym', 'basic_gym', 'home_bodyweight', 'outdoor'],
    category: 'compound',
    difficulty: 'beginner',
    restrictions: ['knee'],
    repRangeMin: 15,
    repRangeMax: 30,
    isUnilateral: false,
    gifUrl: '',
    cues: [
      'Pés na largura dos ombros',
      'Costas retas',
      'Peso nos calcanhares'
    ],
    substituteIds: ['lunges'],
    progressionIds: ['split_squat', 'pistol_squat'],
    regressionIds: ['box_squat'],
    tags: ['bodyweight', 'beginner_friendly'],
  },
];

async function populate() {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  
  admin.initializeApp({
    projectId: 'appcalculotreino-51f23',
  });

  const db = admin.firestore();
  const batch = db.batch();

  for (const ex of exercises) {
    const ref = db.collection('exercises').doc(ex.id);
    batch.set(ref, ex);
  }

  await batch.commit();
  console.log('✅ Banco de exercícios populado com sucesso!');
}

populate().catch(console.error);
