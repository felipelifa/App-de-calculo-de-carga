# BuildFit API

Backend API para o BuildFit - App de prescrição de treino científico.

## Tech Stack

- **Runtime:** Node.js 20
- **Framework:** NestJS 10
- **Language:** TypeScript
- **Database:** PostgreSQL 16 (via Prisma ORM)
- **Cache:** Redis 7
- **Auth:** Firebase Admin SDK
- **Docs:** Swagger (OpenAPI)

## Setup Local

### Pré-requisitos
- Node.js 20+
- Docker (para PostgreSQL e Redis)

### 1. Iniciar banco de dados
```bash
docker-compose up -d
```

### 2. Instalar dependências
```bash
npm install
```

### 3. Configurar variáveis de ambiente
```bash
cp .env.example .env
# Editar .env com suas credenciais
```

### 4. Rodar migrations
```bash
npx prisma migrate dev
```

### 5. Gerar Prisma Client
```bash
npx prisma generate
```

### 6. Iniciar o servidor
```bash
npm run start:dev
```

O servidor estará disponível em `http://localhost:3000`

### Swagger Docs
Acesse `http://localhost:3000/docs` para ver a documentação completa da API.

## Estrutura

```
src/
├── modules/
│   ├── auth/          # Autenticação (Firebase)
│   ├── users/         # Perfis de usuários
│   ├── exercises/     # Biblioteca de exercícios
│   ├── workouts/      # Sessões de treino
│   ├── prescription/  # Motor de prescrição
│   ├── progression/   # Motor de progressão
│   ├── analytics/     # Métricas e gráficos
│   ├── nutrition/     # Bio-Gestão 7.0
│   ├── pr/            # Records pessoais
│   └── pro/           # Sistema Freemium
├── common/
│   ├── guards/        # Auth guard, Pro guard
│   ├── interceptors/  # Logging
│   ├── filters/       # Error handling
│   ├── decorators/    # CurrentUser
│   ├── controllers/   # Health check
│   └── services/      # Prisma, Firebase
└── config/
```

## Endpoints Principais

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/auth/register` | Registrar usuário |
| `GET` | `/api/users/profile` | Obter perfil |
| `PUT` | `/api/users/profile` | Atualizar perfil |
| `GET` | `/api/exercises` | Listar exercícios |
| `GET` | `/api/exercises/:id` | Detalhe do exercício |
| `POST` | `/api/workouts` | Criar treino |
| `GET` | `/api/workouts` | Listar treinos |
| `GET` | `/api/analytics/dashboard` | Dashboard |
| `GET` | `/api/analytics/muscle-volume` | Volume por músculo |
| `POST` | `/api/nutrition/log` | Registrar refeição |
| `POST` | `/api/pro/redeem` | Resgatar token Pro |

## Deploy

### Railway
1. Conectar repositório no Railway
2. Configurar variáveis de ambiente (DATABASE_URL, FIREBASE_SERVICE_ACCOUNT)
3. Deploy automático via GitHub

### Docker
```bash
docker build -t buildfit-api .
docker run -p 3000:3000 --env-file .env buildfit-api
```
