#!/bin/bash
# Script de inicialización para inyectar CSS del logo en Redmine
# Este script se ejecuta una sola vez antes de iniciar Redmine

set -e

REDMINE_DIR="/usr/src/redmine"
LAYOUT_FILE="${REDMINE_DIR}/app/views/layouts/base.html.erb"
CSS_PATH="/stylesheets/custom_logo.css"
MARKER_FILE="/tmp/.logo-css-injected"

# Verificar si ya se inyectó el CSS (usando un archivo marker en /tmp)
if [ -f "$MARKER_FILE" ]; then
    echo "Logo CSS already injected (marker file exists)"
    exit 0
fi

echo "=========================================="
echo "Redmine Logo Initialization Script"
echo "=========================================="

# Función para inyectar CSS en el layout
inject_logo_css() {
    local retry_count=0
    local max_retries=10
    local retry_delay=2
    
    while [ $retry_count -lt $max_retries ]; do
        if [ ! -f "$LAYOUT_FILE" ]; then
            echo "Waiting for layout file... (attempt $((retry_count + 1))/$max_retries)"
            sleep $retry_delay
            retry_count=$((retry_count + 1))
            continue
        fi

        # Verificar si el CSS ya está incluido
        if grep -q "custom_logo.css" "$LAYOUT_FILE"; then
            echo "✓ Logo CSS already present in layout"
            touch "$MARKER_FILE" 2>/dev/null || true
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
            touch "$MARKER_FILE" 2>/dev/null || true
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
            touch "$MARKER_FILE" 2>/dev/null || true
            return 0
        fi

        # Método 3: Buscar </head> y agregar antes
        if grep -q "</head>" "$LAYOUT_FILE"; then
            sed -i '/<\/head>/i\
    <%= stylesheet_link_tag "'"$CSS_PATH"'", :media => "all" %>
' "$LAYOUT_FILE"
            echo "✓ Logo CSS injected in head section"
            touch "$MARKER_FILE" 2>/dev/null || true
            return 0
        fi

        echo "Warning: Could not find suitable location (attempt $((retry_count + 1))/$max_retries)"
        retry_count=$((retry_count + 1))
        sleep $retry_delay
    done

    echo "✗ Failed to inject CSS after $max_retries attempts"
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

# Intentar inyectar el CSS
echo ""
echo "Injecting logo CSS into Redmine layout..."
if inject_logo_css; then
    echo ""
    echo "=========================================="
    echo "✓ Logo CSS injection completed successfully"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "⚠ Logo CSS injection failed, but continuing..."
    echo "=========================================="
fi

exit 0
