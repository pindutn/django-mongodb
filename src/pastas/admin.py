from django.contrib import admin

# Register your models here.
from django.contrib import admin
from pastas.models import *
# Register your models here.
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
    ordering = ['nombre']  # -nombre descendente, nombre ascendente
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
    #date_hierarchy = 'fecha'
    list_display = (
        'fecha',
        'cliente',
    )

    list_filter = (
        'cliente__nombre',
    )

    inlines = [
        DetalleVentaInline]