# Batch Application

โปรเจค Golang + Next.js ที่พัฒนาภายใต้ Docker container พร้อม live reload

## 🏗️ โครงสร้างโปรเจค

```
batch/
├── main.go                 # Golang Fiber server
├── go.mod                  # Go dependencies
├── .air.toml              # Air configuration for live reload
├── Dockerfile             # Production Dockerfile
├── Dockerfile.dev         # Development Dockerfile for Go
├── docker-compose.yml     # Production compose
├── docker-compose.dev.yml # Development compose
├── Makefile              # Build commands
└── static/               # Next.js frontend
    ├── src/
    │   └── app/
    │       ├── layout.tsx
    │       ├── page.tsx
    │       └── globals.css
    ├── package.json
    ├── next.config.js
    ├── tsconfig.json
    ├── tailwind.config.ts
    ├── postcss.config.js
    ├── Dockerfile.dev     # Development Dockerfile for Next.js
    └── dist/             # Built static files (production)
```

## 🚀 การใช้งาน

### Development Mode (แนะนำ)

```bash
# เริ่มต้น development environment พร้อม live reload
make dev

# หรือใช้ docker-compose โดยตรง
docker-compose -f docker-compose.dev.yml up --build
```

**Ports:**
- **Application**: http://localhost:8088 (Golang proxy ไปยัง Next.js)
- Frontend (Next.js): http://localhost:3001 (internal)
- Backend API: http://localhost:8088/api

**ใน Development Mode:**
- Golang server จะ proxy requests ไปยัง Next.js dev server
- API calls (/api/*) จะถูกจัดการโดย Golang
- Static content จะถูก serve จาก Next.js dev server

### Production Mode

```bash
# เริ่มต้น production environment
make prod

# หรือใช้ docker-compose โดยตรง
docker-compose up --build -d
```

**Port:**
- Application: http://localhost:8088

### Local Development (ไม่ใช้ Docker)

**Linux/Mac:**
```bash
# ติดตั้ง dependencies
make install-deps

# รัน development servers
make dev-local
```

**Windows:**
```bash
# ติดตั้ง dependencies
make install-deps

# รัน development servers (เลือกวิธีใดวิธีหนึ่ง)
./dev-local-win.bat          # Batch script (แนะนำ)
./dev-local-win.ps1          # PowerShell script
```

## 🛠️ คำสั่งที่มีประโยชน์

```bash
# ดู help
make help

# Build production images
make build

# ทำความสะอาด containers และ images
make clean

# Build frontend เท่านั้น
make build-frontend

# รัน Go application เท่านั้น
make run-go

# รัน tests
make test

# Format Go code
make fmt

# รัน linter
make lint
```

## 🔧 Features

### Backend (Golang Fiber)
- ✅ Fiber web framework
- ✅ Static file serving
- ✅ CORS middleware
- ✅ Logger middleware
- ✅ Recovery middleware
- ✅ API endpoints (`/api/health`, `/api/hello`)
- ✅ Air live reload ในโหมด development
- ✅ Port 8088

### Frontend (Next.js)
- ✅ Next.js 14 with App Router
- ✅ TypeScript
- ✅ Tailwind CSS
- ✅ pnpm package manager (เร็วกว่า npm)
- ✅ Static export สำหรับ production
- ✅ Live reload ในโหมด development
- ✅ Port 3001 ในโหมด development

### Docker
- ✅ Multi-stage build สำหรับ production
- ✅ Development containers พร้อม live reload
- ✅ Volume mounting สำหรับ development
- ✅ Network configuration
- ✅ Health checks

## 📁 API Endpoints

- `GET /api/health` - Backend health check (with version info)
- `GET /api/ready` - Readiness probe (for Dokploy/K8s)
- `GET /api/live` - Liveness probe (for Dokploy/K8s)
- `GET /api/hello` - Test endpoint
- `GET /health/frontend` - Frontend health check (development only)
- `GET /` - Serve Next.js static files (production) หรือ proxy ไปยัง Next.js dev server (development)

## 🔄 Live Reload

### Development Mode
- **Golang**: ใช้ Air สำหรับ live reload
- **Next.js**: ใช้ Next.js dev server สำหรับ live reload
- **Docker**: Volume mounting เพื่อให้ code changes reflect ทันที
- **Proxy**: Golang server proxy requests ไปยัง Next.js dev server

### Environment Variables
สร้างไฟล์ `.env` ในโฟลเดอร์ root:
```bash
NODE_ENV=development
PORT=8088
FRONTEND_URL=http://localhost:3001
```

### การตั้งค่า Air
ดูการตั้งค่าใน `.air.toml`:
- ไม่ watch `static/` folder เพื่อป้องกัน conflict
- Build ไปที่ `./tmp/main`
- Watch เฉพาะไฟล์ `.go`

## 🌟 การพัฒนา

1. **เริ่มต้น development**:
   ```bash
   make dev
   ```

2. **แก้ไข Golang code**: ไฟล์จะถูก rebuild อัตโนมัติด้วย Air

3. **แก้ไข Next.js code**: หน้าเว็บจะ refresh อัตโนมัติ

4. **Test API**: เข้าไปที่ http://localhost:8088/api/health

5. **ดู Application**: เข้าไปที่ http://localhost:8088 (ทั้ง dev และ prod)

## 📦 Production Deployment

```bash
# Build และ deploy
make prod

# หรือ
docker-compose up --build -d
```

Frontend จะถูก build เป็น static files และ serve ผ่าน Golang Fiber server ที่ port 8088

## 🚀 Dokploy Deployment

โปรเจคนี้รองรับ Dokploy deployment เมื่อ push ขึ้น Git แล้ว:

### การตั้งค่า Dokploy

1. **เชื่อมต่อ Git Repository**:
   - เพิ่ม repository ใน Dokploy dashboard
   - เลือก branch `main` สำหรับ auto-deploy

2. **การตั้งค่าแอปพลิเคชัน**:
   ```json
   {
     "name": "batch-app",
     "type": "dockerfile",
     "dockerfile": "Dockerfile",
     "buildContext": ".",
     "environment": {
       "NODE_ENV": "production",
       "PORT": "8088"
     },
     "ports": [
       {
         "containerPort": 8088,
         "hostPort": 8088
       }
     ]
   }
   ```

3. **Domain Configuration**:
   - ตั้งค่า domain ใน Dokploy dashboard
   - SSL certificate จะถูกสร้างอัตโนมัติ

### Health Check Endpoints

Dokploy จะใช้ endpoints เหล่านี้ในการตรวจสอบสถานะ:

- `GET /api/health` - General health check
- `GET /api/ready` - Readiness probe
- `GET /api/live` - Liveness probe

### Auto-Deploy

เมื่อ push code ขึ้น Git:
1. Dokploy จะ detect changes อัตโนมัติ
2. Build Docker image ใหม่
3. Deploy แอปพลิเคชัน
4. ทำ health check
5. Switch traffic ไปยัง version ใหม่

### Environment Variables

สำหรับ production ใน Dokploy:
```bash
NODE_ENV=production
PORT=8088
# เพิ่ม environment variables อื่นๆ ตามต้องการ
```

## 🐛 Troubleshooting

### Port conflicts
หาก port 3001 หรือ 8088 ถูกใช้งานแล้ว ให้แก้ไขใน `docker-compose.dev.yml`

### Permission issues
ใน Linux/Mac อาจต้องใช้ `sudo` สำหรับ Docker commands

### Windows Development Issues
หาก `dev-local-win.bat` ไม่ทำงาน:
1. ตรวจสอบว่าติดตั้ง `pnpm` และ `air` แล้ว
2. ลองใช้ PowerShell script: `./dev-local-win.ps1`
3. หรือรันแยกใน terminal 2 หน้าต่าง:
   ```bash
   # Terminal 1
   cd static && pnpm run dev
   
   # Terminal 2  
   air -c .air.win.toml
   ```

### Frontend build issues
ตรวจสอบ Node.js version และรัน:
```bash
cd static && pnpm install
```

### pnpm-lock.yaml ไม่มี
หากยังไม่มีไฟล์ `pnpm-lock.yaml` ให้รัน:
```bash
cd static && pnpm install
```
ไฟล์ `pnpm-lock.yaml` จะถูกสร้างขึ้นอัตโนมัติ และควร commit เข้า git
