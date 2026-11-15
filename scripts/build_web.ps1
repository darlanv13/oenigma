# Script de build para Flutter Web com preservação completa dos ícones FontAwesome (sem tree-shaking destrutivo)
# Evita o problema onde ícones aparecem como caixas com 'X' (missing glyphs) na versão Web.

param(
  [switch]$DeployStaging
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Compilando O Enigma para Web (--no-tree-shake-icons)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Compila Player (App do Jogador)
Write-Host "`n[1/2] Compilando Player Web (lib/player/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/player/main.dart --base-href /oenigma/cliente/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Player Web."
  exit $LASTEXITCODE
}

# Se a flag de staging foi passada, copia para gh-pages-staging\cliente
if ($DeployStaging -and (Test-Path "build\gh-pages-staging")) {
  Write-Host "Sincronizando com build\gh-pages-staging\cliente..." -ForegroundColor Green
  if (!(Test-Path "build\gh-pages-staging\cliente")) {
    New-Item -ItemType Directory -Path "build\gh-pages-staging\cliente" -Force | Out-Null
  }
  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging\cliente" -Recurse -Force
  if (Test-Path "build\gh-pages-staging\cliente\.git") {
    Remove-Item -Path "build\gh-pages-staging\cliente\.git" -Recurse -Force
  }
}

# 2. Compila Painel Mestre / Portal Hub Central
Write-Host "`n[2/2] Compilando Painel Mestre / Portal (lib/painel_mestre/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/painel_mestre/main.dart --base-href /oenigma/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar Painel Admin."
  exit $LASTEXITCODE
}

if ($DeployStaging -and (Test-Path "build\gh-pages-staging")) {
  Write-Host "Sincronizando com a raiz de build\gh-pages-staging..." -ForegroundColor Green
  # Salva 404.html customizado antes de copiar se existir
  $has404 = Test-Path "build\gh-pages-staging\404.html"
  $content404 = if ($has404) { Get-Content "build\gh-pages-staging\404.html" -Raw } else { $null }

  Copy-Item -Path "build\web\*" -Destination "build\gh-pages-staging" -Recurse -Force

  # Restaura 404.html de redirecionamento SPA
  if ($content404) {
    Set-Content -Path "build\gh-pages-staging\404.html" -Value $content404 -Force
  }

  # Garante que as subpastas de rotas directas tenham o index.html com base /oenigma/
  $subroutes = @("admin", "studio", "portal", "login", "player", "e")
  foreach ($sub in $subroutes) {
    $dir = "build\gh-pages-staging\$sub"
    if (!(Test-Path $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Copy-Item -Path "build\web\index.html" -Destination "$dir\index.html" -Force
  }
}

Write-Host "`nBuilds Web finalizados e sincronizados com sucesso!" -ForegroundColor Green
