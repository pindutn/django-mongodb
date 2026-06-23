# Tutorial: Despliegue de una Aplicación Django con MongoDB

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Django 6.0](https://img.shields.io/badge/Django%206.0-092E20?style=for-the-badge&logo=django&logoColor=white)
![Python 3.12](https://img.shields.io/badge/Python%203.12-3776AB?style=for-the-badge&logo=python&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)

**Referencia Rápida**

**Mantenido Por:** PINDU

## **Descargo de Responsabilidad:**
El código proporcionado se ofrece "tal cual", sin garantía de ningún tipo, expresa o implícita. En ningún caso los autores o titulares de derechos de autor serán responsables de cualquier reclamo, daño u otra responsabilidad.

## **Donaciones:**
Si encuentras útil este proyecto y deseas contribuir a su mantenimiento, considera hacer una donación. Tu apoyo es muy apreciado.

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/parruccia?country.x=AR&locale.x=es_XC)

## Introducción
Este tutorial te guiará paso a paso en la creación y despliegue de una aplicación Django utilizando Docker, Docker Compose y MongoDB. El objetivo es que puedas levantar un entorno de desarrollo profesional, portable y fácil de mantener, ideal tanto para pruebas como para producción.

Este proyecto está basado en **Fábrica de Pastas**, un sistema de gestión para una fábrica de pastas artesanales desarrollado como trabajo práctico para la materia Bases de Datos de la UTN.

---

## Requisitos Previos
- **Docker** y **Docker Compose** instalados en tu sistema. Puedes consultar la [documentación oficial de Docker](https://docs.docker.com/get-docker/) para la instalación.
- Conocimientos básicos de Python y Django (no excluyente, el tutorial es autoexplicativo).

### Recursos Útiles
- [Tutorial oficial de Django](https://docs.djangoproject.com/en/6.0/intro/tutorial01/)
- [django-mongodb-backend](https://pypi.org/project/django-mongodb-backend/)

---

## 1. Estructura del Proyecto
Crea una carpeta para tu proyecto. En este ejemplo, la llamaremos `fabrica`.

> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal o archivo correspondiente.**
```sh
mkdir fabrica
cd fabrica/
```

---

## 2. Definición de Dependencias
Crea un archivo `requirements.txt` para listar las dependencias de Python necesarias para tu aplicación.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo requirements.txt.**
```txt
# requirements.txt
Django==6.0.*
django-mongodb-backend==6.0.*
pymongo==4.11.*
gunicorn
```

---

## 3. Creación del Dockerfile
El `Dockerfile` define la imagen de Docker que contendrá tu aplicación.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo Dockerfile.**
```dockerfile
FROM python:3.12-slim AS base
LABEL maintainer="Luciano Parruccia <parruccia@yahoo.com.ar>"
LABEL version="2.0"
LABEL description="fabrica de pastas"
RUN mkdir /code
WORKDIR /code
COPY ./requirements.txt .
RUN pip install --upgrade pip \
  && pip install --no-cache-dir -r requirements.txt \
  && rm requirements.txt
COPY ./src /code
CMD ["gunicorn", "--bind", ":8000", "--workers", "3", "app.wsgi"]
```

---

## 4. Configuración de Variables de Entorno
Crea un archivo `.env.db` para almacenar las variables de entorno necesarias para la conexión a MongoDB.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo .env.db.**
```conf
# .env.db

# MongoDB root credentials
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin

# Django DB connection
MONGO_ENGINE=django_mongodb_backend
MONGO_DB_NAME=midb
MONGO_USER=admin
MONGO_PASSWORD=admin
MONGO_HOST=db
MONGO_PORT=27017

# Mongo Express
ME_CONFIG_MONGODB_ADMINUSERNAME=admin
ME_CONFIG_MONGODB_ADMINPASSWORD=admin
ME_CONFIG_MONGODB_SERVER=db
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=admin
```

---

## 5. Definición de Servicios con Docker Compose
El archivo `docker-compose.yml` orquesta los servicios necesarios: MongoDB, backend de Django y Mongo Express para administración visual de la base de datos.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo docker-compose.yml.**
```yml
services:
  db:
    image: mongo
    restart: unless-stopped
    volumes:
      - mongodb_data:/data/db
    env_file:
      - .env.db
    networks:
      - net

  backend:
    build: .
    command: runserver 0.0.0.0:8000
    entrypoint: python3 manage.py
    env_file:
      - .env.db
    expose:
      - "8000"
    ports:
      - "8000:8000"
    volumes:
      - ./src:/code
    depends_on:
      db:
        condition: service_started
    networks:
      - net

  mongo-express:
    image: mongo-express
    restart: unless-stopped
    ports:
      - "8081:8081"
    env_file:
      - .env.db
    depends_on:
      db:
        condition: service_started
    networks:
      - net

networks:
  net:

volumes:
  mongodb_data:
```

---

## 6. Generación y Configuración de la Aplicación

### Generar la estructura base del proyecto y la app

> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose run --rm backend startproject app src
docker compose run --rm backend startapp pastas
sudo chown $USER:$USER -R .
```

### Configuración de `settings.py`
Edita el archivo `settings.py` para configurar la base de datos MongoDB y las apps necesarias.

> **Puedes copiar todo este bloque y pegarlo al final directamente en tu archivo ./src/app/settings.py.**
```python
import os
ALLOWED_HOSTS = [os.environ.get("ALLOWED_HOSTS", "*")]
INSTALLED_APPS += [
    'django_mongodb_backend',
    'pastas',
]
DEFAULT_AUTO_FIELD = 'django_mongodb_backend.fields.ObjectIdAutoField'

MIGRATION_MODULES = {
    "admin": "mongo_migrations.admin",
    "auth": "mongo_migrations.auth",
    "contenttypes": "mongo_migrations.contenttypes",
}

MONGO_ENGINE = os.environ.get("MONGO_ENGINE", "django_mongodb_backend")
MONGO_DB_NAME = os.environ.get("MONGO_DB_NAME", "midb")
MONGO_USER = os.environ.get("MONGO_USER", "admin")
MONGO_PASSWORD = os.environ.get("MONGO_PASSWORD", "admin")
MONGO_HOST = os.environ.get("MONGO_HOST", "db")
MONGO_PORT = os.environ.get("MONGO_PORT", "27017")

DATABASES = {
    'default': {
        'ENGINE': MONGO_ENGINE,
        'NAME': MONGO_DB_NAME,
        'HOST': f"mongodb://{MONGO_USER}:{MONGO_PASSWORD}@{MONGO_HOST}:{MONGO_PORT}/{MONGO_DB_NAME}?authSource=admin",
    }
}
```

### Configuración de `apps.py`
Para usar ObjectId como clave primaria en todas las apps del sistema, crea `app/apps.py`:

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo ./src/app/apps.py.**
```python
from django.contrib.admin.apps import AdminConfig
from django.contrib.auth.apps import AuthConfig
from django.contrib.contenttypes.apps import ContentTypesConfig


class MongoAdminConfig(AdminConfig):
    default_auto_field = "django_mongodb_backend.fields.ObjectIdAutoField"


class MongoAuthConfig(AuthConfig):
    default_auto_field = "django_mongodb_backend.fields.ObjectIdAutoField"


class MongoContentTypesConfig(ContentTypesConfig):
    default_auto_field = "django_mongodb_backend.fields.ObjectIdAutoField"
```

---

## 7. Primeros Pasos con Django

### Migrar la base de datos
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose run --rm backend makemigrations admin auth contenttypes --skip-checks
docker compose run --rm backend makemigrations pastas --skip-checks
docker compose run --rm backend migrate --skip-checks
```

### Crear un superusuario
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose run --rm backend createsuperuser
```

### Iniciar la aplicación
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose up -d backend
```
Accede a la administración de Django en [http://localhost:8000/admin/](http://localhost:8000/admin/)

### Ver logs de los contenedores
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose logs -f
```

---

## 8. Comandos Útiles
- **Aplicar migraciones:**
  > **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
  ```sh
  docker compose run --rm backend makemigrations
  docker compose run --rm backend migrate
  ```
- **Detener y eliminar contenedores:**
  > **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
  ```sh
  docker compose down
  ```
- **Detener y eliminar contenedores con imágenes y volúmenes:**
  > **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
  ```sh
  docker compose down -v --remove-orphans --rmi all
  ```
- **Limpiar recursos de Docker:**
  > **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
  ```sh
  docker system prune -a
  ```
- **Cambiar permisos de archivos:**
  > **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
  ```sh
  sudo chown $USER:$USER -R .
  ```

---

## 9. Modelado de la Aplicación

### Ejemplo de `models.py`
Modelos para la gestión de una fábrica de pastas. Usa `ObjectIdAutoField` como clave primaria (por defecto global) y `on_delete=models.DO_NOTHING` ya que MongoDB no gestiona integridad referencial a nivel de base de datos.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo ./src/pastas/models.py.**
```python
from decimal import Decimal

from django.db import models
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.models import User


class NombreAbstract(models.Model):
    nombre = models.CharField(
        _('Nombre'),
        help_text=_('Nombre descriptivo'),
        max_length=200,
        unique=True,
    )

    def save(self, *args, **kwargs):
        self.nombre = self.nombre.upper()
        return super().save(*args, **kwargs)

    def natural_key(self):
        return (self.nombre,)

    def __str__(self):
        return '{}'.format(self.nombre)

    class Meta:
        abstract = True
        ordering = ['nombre']


class Localidad(NombreAbstract):
    class Meta:
        verbose_name = 'localidad'
        verbose_name_plural = 'localidades'


class Barrio(NombreAbstract):
    class Meta:
        verbose_name = 'barrio'
        verbose_name_plural = 'barrios'


class Provincia(NombreAbstract):
    class Meta:
        verbose_name = 'provincia'
        verbose_name_plural = 'provincias'


class Producto(NombreAbstract):
    ganancia = models.DecimalField(
        _('Ganancia'),
        max_digits=7,
        decimal_places=2,
        help_text=_('Ganancia del producto, expresado en coeficiente.'),
        default=0
    )
    es_relleno = models.BooleanField(
        _('Es Relleno'),
        help_text=_('Especifica si el producto contiene relleno.'),
        default=False
    )

    @property
    def precio(self):
        total = Decimal(0)
        for receta in self.recetas.all():
            total += receta.cantidad * receta.ingrediente.costo
        return round(total * self.ganancia, 2)

    class Meta:
        verbose_name = 'producto'
        verbose_name_plural = 'productos'


class Cliente(NombreAbstract):
    numero_documento = models.BigIntegerField(
        _('numero documento'),
        help_text=_('numero de documento / CUIT'),
    )
    direccion = models.CharField(
        _('dirección'),
        help_text=_('dirección del cliente'),
        max_length=200,
        blank=True,
    )
    celular = models.BigIntegerField(
        _('Celular'),
        help_text=_('Número de celular con característica del/la administrador/a'),
        blank=True,
    )
    telefono = models.BigIntegerField(
        _('teléfono'),
        help_text=_('teléfono fijo'),
        blank=True,
    )
    email = models.EmailField(
        _('email'),
        help_text=_('email del cliente'),
        blank=True,
    )
    barrio = models.ForeignKey(
        Barrio,
        verbose_name=_('barrio'),
        help_text=_('barrio donde reside '),
        related_name='%(app_label)s_%(class)s_related',
        on_delete=models.DO_NOTHING,
        blank=True,
    )
    localidad = models.ForeignKey(
        Localidad,
        verbose_name=_('localidad'),
        help_text=_('localidad donde reside el cliente'),
        related_name='%(app_label)s_%(class)s_related',
        on_delete=models.DO_NOTHING,
        blank=True,
    )
    provincia = models.ForeignKey(
        Provincia,
        verbose_name=_('provincia'),
        help_text=_('provincia donde reside'),
        related_name='%(app_label)s_%(class)s_related',
        on_delete=models.DO_NOTHING,
        blank=True,
    )
    user = models.ForeignKey(
        User,
        help_text=_('Usuario con el que se loguea al sistema'),
        verbose_name='usuario',
        related_name='%(app_label)s_%(class)s',
        related_query_name='%(app_label)s_%(class)s',
        on_delete=models.DO_NOTHING,
        null=True,
        blank=True
    )

    def __str__(self):
        return '{} {}'.format(self.nombre, self.numero_documento)

    class Meta:
        indexes = [
            models.Index(
                fields=[
                    'numero_documento',
                    'user',
                ],
                name='%(app_label)s_%(class)s_unico'
            ),
        ]


class Venta(models.Model):
    fecha = models.DateField(
        _('fecha'),
        help_text=_('fecha de la venta')
    )
    cliente = models.ForeignKey(
        Cliente,
        verbose_name=_('cliente'),
        help_text=_('cliente que realiza la compra'),
        related_name='compras',
        on_delete=models.DO_NOTHING,
        blank=False,
    )

    def __str__(self):
        return '{} {}'.format(self.fecha, self.cliente.nombre)

    class Meta:
        ordering = ['fecha']
        verbose_name = 'venta'
        verbose_name_plural = 'ventas'


class DetalleVenta(models.Model):
    venta = models.ForeignKey(
        Venta,
        verbose_name=_('venta'),
        help_text=_('detalle de la compra'),
        related_name='detalle',
        on_delete=models.DO_NOTHING,
        blank=False,
    )
    cantidad = models.DecimalField(
        _('cantidad'),
        max_digits=7,
        decimal_places=2,
        help_text=_('cantidad'),
        blank=True,
        default=None
    )
    producto = models.ForeignKey(
        Producto,
        verbose_name=_('producto'),
        help_text=_('producto'),
        related_name='detalle',
        on_delete=models.DO_NOTHING,
        blank=False,
    )


class UnidadMedida(NombreAbstract):
    pass


class Ingrediente(NombreAbstract):
    costo = models.DecimalField(
        _('Costo'),
        max_digits=7,
        decimal_places=2,
        help_text=_('Costo del ingrediente expresado en pesos'),
        default=0
    )
    unidad_medida = models.ForeignKey(
        UnidadMedida,
        related_name='ingredientes',
        on_delete=models.DO_NOTHING,
        help_text=_('Unidad de medida del ingrediente'),
    )

    class Meta:
        verbose_name = _('Ingrediente')
        verbose_name_plural = _('Ingredientes')


class Receta(models.Model):
    cantidad = models.DecimalField(
        _('Cantidad'),
        max_digits=7,
        decimal_places=3,
        help_text=_(
            'Cantidad del ingrediente, expresado en su unidad de medida.'),
        default=0
    )
    ingrediente = models.ForeignKey(
        Ingrediente,
        related_name='recetas',
        on_delete=models.DO_NOTHING,
        help_text=_('Ingrediente de la receta'),
    )
    producto = models.ForeignKey(
        Producto,
        related_name='recetas',
        on_delete=models.DO_NOTHING,
        help_text=_('Producto de la receta'),
    )

    class Meta:
        ordering = ['ingrediente']
        verbose_name = _('Producto')
        verbose_name_plural = _('Productos')
```

> **Nota sobre `on_delete`:** Django exige definir `on_delete` en las ForeignKey, pero MongoDB no gestiona integridad referencial a nivel de motor, por lo que el valor elegido es meramente formal. Usamos `DO_NOTHING` para evitar restricciones inexistentes en MongoDB.

---

## 10. Administración de la Aplicación

### Ejemplo de `admin.py`
Registra tus modelos para gestionarlos desde el panel de administración de Django.

> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo ./src/pastas/admin.py.**
```python
from django.contrib import admin
from pastas.models import *


admin.site.register(UnidadMedida)
admin.site.register(Ingrediente)
admin.site.register(Barrio)
admin.site.register(Localidad)
admin.site.register(Provincia)
admin.site.register(Cliente)


class RecetaInline(admin.TabularInline):
    model = Receta
    extra = 0


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    inlines = [
        RecetaInline,
    ]
    list_display = (
        'nombre',
        'precio',
    )
    ordering = ['nombre']
    search_fields = ['nombre']
    list_filter = (
        'nombre',
    )


class DetalleVentaInline(admin.TabularInline):
    model = DetalleVenta
    extra = 0


@admin.register(Venta)
class ComprobanteAdmin(admin.ModelAdmin):
    save_on_top = True
    save_as = True
    list_per_page = 20
    date_hierarchy = 'fecha'
    list_display = (
        'fecha',
        'cliente',
    )
    list_filter = (
        'cliente__nombre',
    )
    inlines = [
        DetalleVentaInline,
    ]
```

---

## 11. Migraciones y Carga de Datos Iniciales

### Realizar migraciones de la app nueva.
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose run --rm backend makemigrations
docker compose run --rm backend migrate
```

Accede a la administración de Django en [http://localhost:8000/admin/](http://localhost:8000/admin/) donde ya se van a ver los cambios realizados en la app, pero todavía sin datos pre cargados.

### Crear y cargar fixtures (datos iniciales)
Crea la carpeta `./src/pastas/fixtures` dentro de tu app y agrega el archivo `initial_data.json` con los datos de ejemplo. Luego, carga los datos:
> **Puedes copiar todo este bloque y pegarlo directamente en tu archivo initial_data.json.**
```json
[
    {
        "model": "pastas.unidadmedida",
        "pk": 1,
        "fields": {
            "nombre": "KILO"
        }
    },
    {
        "model": "pastas.unidadmedida",
        "pk": 2,
        "fields": {
            "nombre": "UNIDAD"
        }
    }
]
```
> **Puedes copiar todo este bloque y pegarlo directamente en tu terminal.**
```sh
docker compose run --rm backend loaddata initial_data
```

---

## Conclusión
Con estos pasos, tendrás un entorno Django con MongoDB profesional, portable y listo para desarrollo o producción. Recuerda consultar la documentación oficial de Django y Docker para profundizar en cada tema. ¡Éxitos en tu proyecto!

---
