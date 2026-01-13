# Solución de Logo Corporativo para Redmine

## Estructura de Carpetas Final

```
redmine/
├── docker-compose.yml
├── docker-entrypoint-wrapper.sh
├── init-redmine-logo.sh
├── img/
│   └── logo.png
├── public/
│   ├── images/
│   │   └── logo.png
│   └── stylesheets/
│       └── custom_logo.css
└── themes/
    └── opale/
        └── ...
```

## Archivos Principales

### 1. `docker-compose.yml`
- **Volúmenes montados:**
  - `./public/images` → `/usr/src/redmine/public/images` (logo.png)
  - `./public/stylesheets` → `/usr/src/redmine/public/stylesheets` (custom_logo.css)
  - `./docker-entrypoint-wrapper.sh` → `/docker-entrypoint-wrapper.sh` (script de inicialización)
- **Entrypoint personalizado:** Ejecuta el wrapper script antes del entrypoint original de Redmine

### 2. `docker-entrypoint-wrapper.sh`
- Script que se ejecuta al arrancar el contenedor
- Inyecta automáticamente el CSS en el layout base de Redmine (`base.html.erb`)
- Busca la sección `<head>` y agrega el link al CSS personalizado
- Crea backups del layout antes de modificarlo
- Reintenta hasta 5 veces si el layout no está disponible

### 3. `public/stylesheets/custom_logo.css`
- CSS global que fuerza la visualización del logo en:
  - **Header:** Logo en el encabezado de todas las páginas
  - **Login:** Logo centrado arriba del formulario de login
  - **Todas las páginas:** Logo fijo en la esquina superior izquierda
- Usa `!important` para sobrescribir estilos del theme
- Funciona independientemente del theme activo

### 4. `public/images/logo.png`
- Logo corporativo montado desde el host
- Accesible públicamente en `/images/logo.png`

## ¿Por Qué Funciona?

### 1. **Montaje de Volúmenes Persistentes**
Los volúmenes montados en `docker-compose.yml` aseguran que:
- El logo y CSS estén disponibles dentro del contenedor
- Los cambios persistan al reiniciar contenedores
- No se pierdan al actualizar la imagen de Redmine

### 2. **Inyección Automática de CSS**
El script `docker-entrypoint-wrapper.sh`:
- Modifica el layout base de Redmine (`base.html.erb`)
- Agrega el link al CSS personalizado en la sección `<head>`
- Se ejecuta automáticamente al arrancar el contenedor
- No requiere intervención manual

### 3. **CSS con Especificidad Alta**
El CSS usa:
- Selectores específicos (`#header > h1`, `body.action-login`)
- `!important` para sobrescribir estilos del theme
- Múltiples métodos de posicionamiento (background-image, pseudo-elementos)
- Media queries para responsive design

### 4. **Independencia del Theme**
- El CSS se carga después de los estilos del theme
- Usa `!important` para forzar la visualización
- No depende de variables o configuraciones del theme
- Funciona con cualquier theme (default, opale, etc.)

### 5. **Persistencia**
- Los archivos están montados desde el host
- El layout modificado se guarda en el contenedor
- Al reiniciar, el script verifica si el CSS ya está inyectado
- No se requiere reconfiguración manual

## Flujo de Ejecución

1. **Docker Compose inicia el contenedor**
2. **Se ejecuta `docker-entrypoint-wrapper.sh`**
3. **El script verifica que el layout existe**
4. **Inyecta el CSS en `base.html.erb`**
5. **Ejecuta el entrypoint original de Redmine**
6. **Redmine carga el layout modificado con el CSS**
7. **El CSS fuerza la visualización del logo en todas las páginas**

## Ventajas de Esta Solución

✅ **Sin plugins:** No requiere instalar plugins de Redmine  
✅ **Persistente:** Sobrevive a reinicios de contenedores  
✅ **Universal:** Funciona con cualquier theme  
✅ **Automático:** No requiere configuración manual  
✅ **Robusto:** Múltiples métodos de inyección y fallback  
✅ **Mantenible:** Fácil de actualizar el logo o CSS  

## Mantenimiento

### Cambiar el Logo
1. Reemplazar `img/logo.png` con el nuevo logo
2. Copiar a `public/images/logo.png`
3. Reiniciar el contenedor: `docker-compose restart redmine`

### Modificar el CSS
1. Editar `public/stylesheets/custom_logo.css`
2. Los cambios se aplican automáticamente (el archivo está montado)
3. Recargar la página en el navegador (Ctrl+F5 para forzar recarga)

### Verificar que Funciona
1. Acceder a Redmine: `http://localhost:3000`
2. Verificar logo en:
   - Header de cualquier página
   - Página de login
   - Esquina superior izquierda (en todas las páginas excepto login)
