# Script de build para Flutter Web com preservação completa dos ícones FontAwesome (sem tree-shaking destrutivo)
# Compila os 3 módulos do ecossistema: Player, Creator Studio e Painel Mestre

param(
  [switch]$DeployStaging
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Compilando O Enigma para Web (--no-tree-shake-icons)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Compila Player
Write-Host "`n[1/3] Compilando Player (lib/player/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/player/main.dart --base-href /oenigma/player/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Player."
  exit $LASTEXITCODE
}

if ($DeployStaging -and (Test-Path "build\gh-pages-staging\player")) {
  Write-Host "Sincronizando com build\gh-pages-staging\player..." -ForegroundColor Green
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\player" -Recurse -Force
}

# 2. Compila Creator Studio
Write-Host "`n[2/3] Compilando Creator Studio (lib/creator_studio/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/creator_studio/main.dart --base-href /oenigma/creator/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Creator Studio."
  exit $LASTEXITCODE
}

if ($DeployStaging -and (Test-Path "build\gh-pages-staging\creator")) {
  Write-Host "Sincronizando com build\gh-pages-staging\creator..." -ForegroundColor Green
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\creator" -Recurse -Force
}

# 3. Compila Painel Mestre
Write-Host "`n[3/3] Compilando Painel Mestre (lib/painel_mestre/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/painel_mestre/main.dart --base-href /oenigma/mestre/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Painel Mestre."
  exit $LASTEXITCODE
}

if ($DeployStaging -and (Test-Path "build\gh-pages-staging\mestre")) {
  Write-Host "Sincronizando com build\gh-pages-staging\mestre..." -ForegroundColor Green
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\mestre" -Recurse -Force
}

Write-Host "`nTodos os builds Web finalizados com sucesso!" -ForegroundColor Green
