#!/bin/bash
# Wrapper script para el entrypoint de Redmine que inyecta el CSS del logo y JavaScript personalizado
# Este script se ejecuta antes del entrypoint original de Redmine

set -e

REDMINE_DIR="/usr/src/redmine"
LAYOUT_FILE="${REDMINE_DIR}/app/views/layouts/base.html.erb"
CSS_PATH="/stylesheets/custom_logo.css"
JS_PATH="/javascripts/custom_home.js"
MAX_RETRIES=5
RETRY_DELAY=3

echo "=========================================="
echo "Redmine Customization Initialization Script"
echo "=========================================="

# Función para inyectar CSS en el layout
inject_logo_css() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if [ ! -f "$LAYOUT_FILE" ]; then
            echo "Waiting for layout file to be available... (attempt $((retry_count + 1))/$MAX_RETRIES)"
            sleep $RETRY_DELAY
            retry_count=$((retry_count + 1))
            continue
        fi

        # Verificar si el CSS ya está incluido
        if grep -q "custom_logo.css" "$LAYOUT_FILE"; then
            echo "✓ Logo CSS already injected in layout"
            return 0
        fi

        # Crear backup
        BACKUP_FILE="${LAYOUT_FILE}.bak.$(date +%s)"
        cp "$LAYOUT_FILE" "$BACKUP_FILE" 2>/dev/null || true
        echo "Created backup: $BACKUP_FILE"

        # Método 1: Buscar la línea con stylesheet_link_tag para application y agregar después
        if grep -q "stylesheet_link_tag.*application" "$LAYOUT_FILE"; then
            # Insertar después de la línea de application stylesheet
            sed -i '/stylesheet_link_tag.*application/a\
    <%= stylesheet_link_tag "'"$CSS_PATH"'", :media => "all" %>
' "$LAYOUT_FILE"
            echo "✓ Logo CSS injected successfully after application stylesheet"
            return 0
        fi

        # Método 2: Buscar cualquier stylesheet_link_tag
        if grep -q "stylesheet_link_tag" "$LAYOUT_FILE"; then
            # Insertar después de la última línea de stylesheet_link_tag
            sed -i '/stylesheet_link_tag/{
a\
    <%= stylesheet_link_tag "'"$CSS_PATH"'", :media => "all" %>
}' "$LAYOUT_FILE"
            echo "✓ Logo CSS injected after stylesheet tags"
            return 0
        fi

        # Método 3: Buscar </head> y agregar antes
        if grep -q "</head>" "$LAYOUT_FILE"; then
            sed -i '/<\/head>/i\
    <%= stylesheet_link_tag "'"$CSS_PATH"'", :media => "all" %>
' "$LAYOUT_FILE"
            echo "✓ Logo CSS injected in head section"
            return 0
        fi

        echo "Warning: Could not find suitable location to inject CSS (attempt $((retry_count + 1))/$MAX_RETRIES)"
        retry_count=$((retry_count + 1))
        sleep $RETRY_DELAY
    done

    echo "✗ Failed to inject CSS after $MAX_RETRIES attempts"
    return 1
}

# Función para inyectar JavaScript en el layout
inject_custom_js() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if [ ! -f "$LAYOUT_FILE" ]; then
            echo "Waiting for layout file to be available... (attempt $((retry_count + 1))/$MAX_RETRIES)"
            sleep $RETRY_DELAY
            retry_count=$((retry_count + 1))
            continue
        fi

        # Verificar si el JS ya está incluido
        if grep -q "custom_home.js" "$LAYOUT_FILE"; then
            echo "✓ Custom JS already injected in layout"
            return 0
        fi

        # Método 1: Buscar </head> y agregar antes (más confiable)
        if grep -q "</head>" "$LAYOUT_FILE"; then
            # Inyectar script tag directamente antes de </head>
            sed -i '/<\/head>/i\
    <script src="/javascripts/custom_home.js"></script>
' "$LAYOUT_FILE"
            echo "✓ Custom JS injected in head section (inline script tag)"
            return 0
        fi

        # Método 2: Buscar javascript_include_tag y agregar después
        if grep -q "javascript_include_tag" "$LAYOUT_FILE"; then
            sed -i '/javascript_include_tag/{
a\
    <%= javascript_include_tag "'"$JS_PATH"'", :defer => false %>
}' "$LAYOUT_FILE"
            echo "✓ Custom JS injected after javascript tags"
            return 0
        fi

        # Método 3: Buscar </body> y agregar antes
        if grep -q "</body>" "$LAYOUT_FILE"; then
            # Intentar insertar antes de </body>
            sed -i '/<\/body>/i\
    <%= javascript_include_tag "'"$JS_PATH"'", :defer => false %>
' "$LAYOUT_FILE"
            echo "✓ Custom JS injected successfully before </body>"
            return 0
        fi

        echo "Warning: Could not find suitable location to inject JS (attempt $((retry_count + 1))/$MAX_RETRIES)"
        retry_count=$((retry_count + 1))
        sleep $RETRY_DELAY
    done

    echo "✗ Failed to inject JS after $MAX_RETRIES attempts"
    return 1
}

# Verificar que los archivos necesarios existen
echo "Checking required files..."
if [ ! -f "/usr/src/redmine/public/images/logo.png" ]; then
    echo "⚠ Warning: Logo file not found at /usr/src/redmine/public/images/logo.png"
fi

if [ ! -f "/usr/src/redmine/public/stylesheets/custom_logo.css" ]; then
    echo "⚠ Warning: CSS file not found at /usr/src/redmine/public/stylesheets/custom_logo.css"
fi

if [ ! -f "/usr/src/redmine/public/javascripts/custom_home.js" ]; then
    echo "⚠ Warning: JS file not found at /usr/src/redmine/public/javascripts/custom_home.js"
fi

# Intentar inyectar el CSS
echo ""
echo "Injecting logo CSS into Redmine layout..."
inject_logo_css

# Intentar inyectar el JavaScript
echo ""
echo "Injecting custom JavaScript into Redmine layout..."
inject_custom_js

echo ""
echo "=========================================="
echo "Starting Redmine..."
echo "=========================================="

# Ejecutar el entrypoint original de Redmine
exec /docker-entrypoint.sh "$@"
