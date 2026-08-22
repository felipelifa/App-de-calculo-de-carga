import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');

  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:3001',
      'https://buildfit-nine.vercel.app',
      'https://app-calculo-carga.vercel.app',
    ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('BuildFit API')
    .setDescription('API para prescrição de treino científico e nutrição bio-adaptativa')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Autenticação e autorização')
    .addTag('users', 'Perfis de usuários')
    .addTag('exercises', 'Biblioteca de exercícios')
    .addTag('workouts', 'Sessões de treino')
    .addTag('prescription', 'Motor de prescrição de treinos')
    .addTag('progression', 'Motor de progressão de carga')
    .addTag('analytics', 'Métricas e gráficos')
    .addTag('nutrition', 'Bio-Gestão 7.0')
    .addTag('pr', 'Records pessoais')
    .addTag('pro', 'Sistema Freemium')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`BuildFit API running on http://localhost:${port}`);
  console.log(`Swagger docs: http://localhost:${port}/docs`);
}

bootstrap();
