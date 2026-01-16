# Script para importar backup de Redmine
Write-Host "Esperando a que MySQL este listo..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Buscar el archivo SQL en el directorio backup
$backupFile = Get-ChildItem backup\*.sql | Select-Object -First 1

if (-not $backupFile) {
    Write-Host "ERROR: No se encontro ningun archivo .sql en el directorio backup" -ForegroundColor Red
    exit 1
}

Write-Host "Archivo encontrado: $($backupFile.Name)" -ForegroundColor Green
Write-Host "Importando backup a la base de datos..." -ForegroundColor Yellow

# Importar el backup usando docker exec
Write-Host "Ejecutando importacion..." -ForegroundColor Cyan
Get-Content $backupFile.FullName -Raw | docker exec -i redmine_db mysql -uroot -proot redmine

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK: Backup importado exitosamente!" -ForegroundColor Green
    Write-Host "La base de datos Redmine ha sido restaurada." -ForegroundColor Green
    Write-Host ""
    Write-Host "Reiniciando contenedor de Redmine..." -ForegroundColor Yellow
    docker-compose restart redmine
} else {
    Write-Host ""
    Write-Host "ERROR: Error al importar el backup. Codigo de salida: $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
