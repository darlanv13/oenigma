# Script de build para Flutter Web com preservação completa dos ícones FontAwesome (sem tree-shaking destrutivo)
# Evita o problema onde ícones aparecem como caixas com 'X' (missing glyphs) na versão Web.

param(
  [switch]$DeployStaging
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Compilando O Enigma para Web (--no-tree-shake-icons)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Compila App Cliente
Write-Host "`n[1/2] Compilando App Cliente (lib/app_cliente/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/app_cliente/main.dart --base-href /oenigma/cliente/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar App Cliente."
  exit $LASTEXITCODE
}

# Se a flag de staging foi passada, copia para gh-pages-staging
if ($DeployStaging -and (Test-Path "build\gh-pages-staging\cliente")) {
  Write-Host "Sincronizando com build\gh-pages-staging\cliente..." -ForegroundColor Green
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\cliente" -Recurse -Force
}

# 2. Compila Painel Admin
Write-Host "`n[2/2] Compilando Painel Admin (lib/painel_admin_web/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/painel_admin_web/main.dart --base-href /oenigma/admin/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Painel Admin."
  exit $LASTEXITCODE
}

if ($DeployStaging -and (Test-Path "build\gh-pages-staging\admin")) {
  Write-Host "Sincronizando com build\gh-pages-staging\admin..." -ForegroundColor Green
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\admin" -Recurse -Force
}

Write-Host "`nBuilds Web finalizados com sucesso!" -ForegroundColor Green
