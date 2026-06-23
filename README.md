# django-mongodb

Proyecto **Fábrica de Pastas** — sistema de gestión para una fábrica de pastas artesanales. Desarrollado como trabajo práctico para la materia Bases de Datos de la UTN.

## Stack

- **Django 6.0** con **MongoDB** como motor de base de datos mediante `django-mongodb-backend`
- **Docker Compose** para orquestar: MongoDB, Django + Gunicorn, y Mongo Express
- Clave primaria por defecto: `ObjectIdAutoField` (ObjectId de MongoDB)

## Estructura del proyecto

```
├── src/
│   ├── app/                    # Configuración del proyecto Django
│   │   ├── settings.py         # Settings con conexión a MongoDB
│   │   ├── apps.py             # AppConfigs personalizados (admin, auth, contenttypes)
│   │   └── urls.py             # Ruta admin/
│   ├── pastas/                 # App principal
│   │   ├── models.py           # Modelos de dominio
│   │   ├── admin.py            # Configuración del admin
│   │   └── fixtures/           # Datos de semilla (initial_data.json)
│   ├── mongo_migrations/       # Migraciones para contrib apps con ObjectId
│   │   ├── admin/
│   │   ├── auth/
│   │   └── contenttypes/
│   └── manage.py
├── docker-compose.yml           # Servicios: db, backend, mongo-express
├── Dockerfile                   # Python 3.12-slim + Gunicorn
├── init.sh                      # Script de inicialización completo
├── .env.db                      # Variables de entorno MongoDB
└── requirements.txt             # Django 6.0, django-mongodb-backend, pymongo
```

## Modelos

| Modelo          | Descripción                                               |
|-----------------|-----------------------------------------------------------|
| `Producto`      | Producto con coeficiente de ganancia y precio calculado según receta |
| `Ingrediente`   | Ingrediente con costo y unidad de medida                  |
| `Receta`        | Relación producto-ingrediente con cantidad                |
| `UnidadMedida`  | Unidades de medida (KILO, UNIDAD, etc.)                   |
| `Cliente`       | Cliente con datos de contacto, documento y dirección geográfica |
| `Venta`         | Venta con fecha y cliente                                 |
| `DetalleVenta`  | Detalle de venta (producto + cantidad)                    |
| `Provincia` / `Localidad` / `Barrio` | Datos geográficos de referencia         |

El precio del `Producto` se calcula como: `suma(cantidad * costo_ingrediente) * ganancia`.

## Inicio rápido

```bash
./init.sh
```

El script `init.sh`:
1. Detiene contenedores previos
2. Construye la imagen del backend
3. Levanta los servicios con Docker Compose
4. Espera la conexión a MongoDB
5. Genera y aplica migraciones
6. Crea el superusuario `admin` / contraseña `sa`
7. Carga los datos de semilla

### Accesos

| Servicio       | URL                          |
|----------------|------------------------------|
| Django Admin   | http://localhost:8000/admin/ |
| Mongo Express  | http://localhost:8081        |

- **Usuario:** `admin`
- **Contraseña (Django):** `sa`
- **Contraseña (MongoDB):** `admin`

## Configuración de base de datos

La conexión a MongoDB se configura mediante variables de entorno en `.env.db`:

| Variable         | Valor por defecto |
|------------------|-------------------|
| `MONGO_ENGINE`   | `django_mongodb_backend` |
| `MONGO_DB_NAME`  | `midb`            |
| `MONGO_USER`     | `admin`           |
| `MONGO_PASSWORD` | `admin`            |
| `MONGO_HOST`     | `db`              |
| `MONGO_PORT`     | `27017`           |

## Licencia

GNU General Public License v3.
