/**
 * Seed Script — Extrai exercícios do exercise_library.dart e insere no PostgreSQL
 *
 * Uso:
 *   npx ts-node prisma/seed.ts
 *
 * Pré-requisitos:
 *   - PostgreSQL rodando (docker-compose up -d)
 *   - npx prisma migrate dev
 *   - npx prisma generate
 */

import { PrismaClient } from '@prisma/client';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const prisma = new PrismaClient();

async function main() {
  console.log('Iniciando seed de exercícios...');

  const libPath = join(__dirname, '..', '..', '..', 'app_flutter', 'lib', 'core', 'data', 'exercise_library.dart');
  if (!existsSync(libPath)) {
    throw new Error(`Exercise library not found at ${libPath}`);
  }
  const content = readFileSync(libPath, 'utf-8');

  const exercises = parseExercises(content);
  console.log(`Encontrados ${exercises.length} exercícios no arquivo Dart`);

  let created = 0;
  let skipped = 0;

  for (const ex of exercises) {
    try {
      await prisma.exercise.upsert({
        where: { id: ex.id },
        update: ex,
        create: ex,
      });
      created++;
    } catch (e: any) {
      console.error(`Erro ao inserir ${ex.id}: ${e.message}`);
      skipped++;
    }
  }

  console.log(`Seed concluído: ${created} criados/atualizados, ${skipped} pulados`);
}

function parseExercises(content: string) {
  const exercises: any[] = [];

  const exerciseRegex = /ExerciseModel\(\s*id:\s*'([^']+)'([\s\S]*?)(?=ExerciseModel\(|;\s*$)/g;

  let match;
  while ((match = exerciseRegex.exec(content)) !== null) {
    const id = match[1];
    const body = match[2];

    try {
      const ex = {
        id,
        name: extractString(body, 'name') || id,
        nameEn: extractString(body, 'nameEn') || null,
        primaryMuscles: extractStringArray(body, 'primaryMuscles'),
        secondaryMuscles: extractStringArray(body, 'secondaryMuscles'),
        movementPattern: extractString(body, 'movementPattern') || 'isolation',
        equipment: extractStringArray(body, 'equipment'),
        environment: extractStringArray(body, 'environment').length > 0
          ? extractStringArray(body, 'environment')
          : ['gym'],
        category: extractString(body, 'category') || 'isolation',
        difficulty: extractString(body, 'difficulty') || 'beginner',
        restrictions: extractStringArray(body, 'restrictions'),
        repRangeMin: extractInt(body, 'repRangeMin') || 8,
        repRangeMax: extractInt(body, 'repRangeMax') || 12,
        isUnilateral: extractBool(body, 'isUnilateral'),
        gifUrl: extractString(body, 'gifUrl'),
        videoUrl: extractString(body, 'videoUrl'),
        cues: extractStringArray(body, 'cues'),
        instructions: extractStringArray(body, 'instructions'),
        substituteIds: extractStringArray(body, 'substituteIds'),
        progressionIds: extractStringArray(body, 'progressionIds'),
        regressionIds: extractStringArray(body, 'regressionIds'),
        tags: extractStringArray(body, 'tags'),
        spinalLoad: extractDouble(body, 'spinalLoad'),
        shoulderStress: extractDouble(body, 'shoulderStress'),
        kneeStress: extractDouble(body, 'kneeStress'),
        cnsLoad: extractDouble(body, 'cnsLoad'),
        stabilityType: extractString(body, 'stabilityType') || 'none',
        lengthBias: extractString(body, 'lengthBias') || 'mid_range',
        skillLevel: extractInt(body, 'skillLevel') || 1,
      };

      exercises.push(ex);
    } catch (e) {
      // Ignorar exercícios com erro de parsing
    }
  }

  return exercises;
}

function extractString(body: string, field: string): string | null {
  const regex = new RegExp(`${field}:\\s*'([^']*)'`);
  const match = body.match(regex);
  return match ? match[1] : null;
}

function extractStringArray(body: string, field: string): string[] {
  const regex = new RegExp(`${field}:\\s*\\[([^\\]]*)\\]`);
  const match = body.match(regex);
  if (!match) return [];

  const content = match[1].trim();
  if (!content) return [];

  const items: string[] = [];
  const itemRegex = /'([^']*)'/g;
  let itemMatch;
  while ((itemMatch = itemRegex.exec(content)) !== null) {
    items.push(itemMatch[1]);
  }
  return items;
}

function extractInt(body: string, field: string): number | null {
  const regex = new RegExp(`${field}:\\s*(\\d+)`);
  const match = body.match(regex);
  return match ? parseInt(match[1], 10) : null;
}

function extractDouble(body: string, field: string): number {
  const regex = new RegExp(`${field}:\\s*([\\d.]+)`);
  const match = body.match(regex);
  return match ? parseFloat(match[1]) : 0.0;
}

function extractBool(body: string, field: string): boolean {
  const regex = new RegExp(`${field}:\\s*(true|false)`);
  const match = body.match(regex);
  return match ? match[1] === 'true' : false;
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
