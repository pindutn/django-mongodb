#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# Fábrica de Pastas — Inicialización del proyecto
# ──────────────────────────────────────────────

NC=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
WHITE=$'\033[1;37m'

info()  { printf '%b\n' "${CYAN}  →${NC} $*"; }
ok()    { printf '%b\n' "${GREEN}  ✔${NC} $*"; }
warn()  { printf '%b\n' "${YELLOW}  ⚠${NC} $*"; }
step()  { printf '%b\n' "\n${BOLD}${BLUE}━━━ $* ━━━${NC}"; }
err()   { printf '%b\n' "${RED}  ✘${NC} $*"; }

# ──────────────────────────────────────────────
# Variables de entorno
# ──────────────────────────────────────────────
ENV_FILE="$(dirname "$0")/.env.db"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  err "Archivo $ENV_FILE no encontrado"
  exit 1
fi

COMPOSE_PROJECT="${COMPOSE_PROJECT:-fabrica}"

printf '%b\n' ""
printf '%b\n' "${BOLD}${MAGENTA}  ╔══════════════════════════════════════════╗${NC}"
printf '%b\n' "${BOLD}${MAGENTA}  ║     FÁBRICA DE PASTAS — Inicialización   ║${NC}"
printf '%b\n' "${BOLD}${MAGENTA}  ╚══════════════════════════════════════════╝${NC}"
printf '%b\n' ""

step "Deteniendo contenedores anteriores"
docker compose -p "$COMPOSE_PROJECT" down -v --remove-orphans 2>/dev/null && ok "Contenedores eliminados" || warn "No había contenedores previos"

step "Construyendo imagen backend"
docker compose -p "$COMPOSE_PROJECT" build --no-cache backend
ok "Imagen construida"

step "Iniciando servicios"
docker compose -p "$COMPOSE_PROJECT" up -d
ok "Servicios levantados"

step "Esperando conexión a MongoDB"
for i in $(seq 1 30); do
  if docker compose -p "$COMPOSE_PROJECT" exec -T backend python -c "
import os
from pymongo import MongoClient
user = os.environ.get('MONGO_USER', 'admin')
password = os.environ.get('MONGO_PASSWORD', 'admin123')
host = os.environ.get('MONGO_HOST', 'db')
port = os.environ.get('MONGO_PORT', '27017')
c = MongoClient(f'mongodb://{user}:{password}@{host}:{port}/admin')
c.admin.command('ping')
print('ok')
" 2>/dev/null | grep -q ok; then
    ok "MongoDB listo (intento $i)"
    break
  fi
  info "Esperando MongoDB — intento $i/30..."
  sleep 2
done

step "Generando migraciones del sistema (admin, auth, contenttypes)"
docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py makemigrations admin auth contenttypes --skip-checks
ok "Migraciones del sistema generadas"

step "Generando migraciones de la app pastas"
docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py makemigrations pastas --skip-checks
ok "Migraciones de pastas generadas"

step "Aplicando migraciones"
docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py migrate --skip-checks
ok "Migraciones aplicadas"

SU_USER="${SU_USER:-admin}"
SU_EMAIL="${SU_EMAIL:-admin@example.com}"
SU_PASSWORD="${SU_PASSWORD:-admin}"

step "Creando superusuario"
if docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py createsuperuser \
  --noinput --username "$SU_USER" --email "$SU_EMAIL" 2>/dev/null; then
  ok "Superusuario creado"
else
  warn "El superusuario ya existía"
fi

step "Configurando contraseña"
docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
try:
    u = User.objects.get(username='$SU_USER')
    u.set_password('$SU_PASSWORD')
    u.save()
except User.DoesNotExist:
    print('usuario no encontrado')
"
ok "Contraseña configurada"

step "Cargando datos iniciales"
docker compose -p "$COMPOSE_PROJECT" exec -T backend python manage.py loaddata initial_data
ok "Datos iniciales cargados"

# ──────────────────────────────────────────────
printf '%b\n' ""
box_width=55
box_inner_width=$((box_width - 4))
box_border=$(printf '%*s' "$box_inner_width" '' | tr ' ' '─')
printf '%b\n' "${GREEN}${BOLD}  ┌${box_border}┐${NC}"
printf '%b\n' "${GREEN}${BOLD}  │  ✅  Proyecto listo$(printf '%*s' 31 '')│${NC}"
printf '%b\n' "${GREEN}${BOLD}  ├${box_border}┤${NC}"
printf '%b\n' "${GREEN}${BOLD}  │  ${NC}${CYAN}Admin:${NC}        ${WHITE}http://localhost:8000/admin/${NC}${GREEN}       │${NC}"
printf '%b\n' "${GREEN}${BOLD}  │  ${NC}${CYAN}MongoExpress:${NC}  ${WHITE}http://localhost:8081/${NC}${GREEN}            │${NC}"
printf '%b\n' "${GREEN}${BOLD}  │  ${NC}${CYAN}Usuario:${NC}      ${WHITE}${SU_USER}${NC}${GREEN}                              │${NC}"
printf '%b\n' "${GREEN}${BOLD}  │  ${NC}${CYAN}Contraseña:${NC}   ${WHITE}${SU_PASSWORD}${NC}${GREEN}                                 │${NC}"
printf '%b\n' "${GREEN}${BOLD}  └${box_border}┘${NC}"
printf '%b\n' ""
