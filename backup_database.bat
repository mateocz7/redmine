@echo off
setlocal enabledelayedexpansion
REM Script para crear backup de la base de datos Redmine
REM Genera un archivo SQL con fecha y hora en la carpeta backup

echo ==========================================
echo Backup de Base de Datos Redmine
echo ==========================================
echo.

REM Verificar que el contenedor de MySQL esté corriendo
echo Verificando que el contenedor redmine_db esté corriendo...
podman ps --filter name=redmine_db --format "{{.Names}}" | findstr /C:"redmine_db" >nul
if errorlevel 1 (
    echo ERROR: El contenedor redmine_db no esta corriendo.
    echo Por favor, ejecuta: podman compose up -d
    pause
    exit /b 1
)

echo Contenedor encontrado. Iniciando backup...
echo.

REM Crear la carpeta backup si no existe
if not exist "backup" mkdir backup

REM Generar nombre de archivo con fecha y hora usando PowerShell
for /f "delims=" %%I in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HHmm'"') do set timestamp=%%I
set nombre_archivo=backup\redmine_backup_!timestamp!.sql

echo Fecha y hora del backup: !timestamp!
echo Archivo de salida: !nombre_archivo!
echo.

REM Crear el backup usando mysqldump dentro del contenedor
echo Creando backup de la base de datos...
podman exec redmine_db mysqldump -uroot -proot --single-transaction --routines --triggers redmine > "!nombre_archivo!" 2>nul

if errorlevel 1 (
    echo.
    echo ERROR: No se pudo crear el backup. Verifica que el contenedor este corriendo.
    pause
    exit /b 1
)

REM Verificar que el archivo se creó correctamente
if exist "!nombre_archivo!" (
    for %%A in ("!nombre_archivo!") do set size=%%~zA
    set /a sizeKB=!size!/1024
    echo.
    echo ==========================================
    echo Backup completado exitosamente!
    echo ==========================================
    echo Archivo: !nombre_archivo!
    echo Tamaño: !sizeKB! KB
    echo.
    echo El backup se guardo en la carpeta: backup\
    echo.
) else (
    echo.
    echo ERROR: El archivo de backup no se creo correctamente.
    pause
    exit /b 1
)

pause
