FROM redmine:latest

# Copiar el script wrapper
COPY docker-entrypoint-wrapper.sh /docker-entrypoint-wrapper.sh

# Asegurar que el script tenga terminaciones de línea Unix y permisos de ejecución
RUN sed -i 's/\r$//' /docker-entrypoint-wrapper.sh && \
    chmod +x /docker-entrypoint-wrapper.sh && \
    head -1 /docker-entrypoint-wrapper.sh | grep -q '^#!/bin/bash' || (echo "Error: Script format issue" && exit 1)

# Establecer el entrypoint
ENTRYPOINT ["/docker-entrypoint-wrapper.sh"]
