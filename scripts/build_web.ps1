# Script de build para Flutter Web com preservação completa dos ícones FontAwesome (sem tree-shaking destrutivo)
# Suporta a nova arquitetura do O Enigma:
# - Painel Mestre (Super Admin & Multi-Tenancy)
# - Creator Studio (Criadores / Influenciadores)
# - Player (Web Player & Cliente Caçador)
# - Portal Hub (Portal central com rotas SPA para GitHub Pages)

param(
  [switch]$DeployGhPages
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Compilando O Enigma para Web (--no-tree-shake-icons)" -ForegroundColor Cyan
Write-Host " Módulos: Painel Mestre | Creator Studio | Player" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Compilação Principal da Plataforma Web (Portal + Mestre + Studio + WebPlayer)
Write-Host "`n[1/1] Compilando Plataforma Web (lib/painel_mestre/main.dart)..." -ForegroundColor Yellow
flutter build web -t lib/painel_mestre/main.dart --base-href /oenigma/ --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar a Plataforma Web."
  exit $LASTEXITCODE
}

Write-Host "Configurando suporte SPA para GitHub Pages (/admin, /studio, /creator, /player, /e)..." -ForegroundColor Green

# Cria arquivo .nojekyll para o GitHub Pages
New-Item -Path "build\web\.nojekyll" -ItemType File -Force | Out-Null

# Copia index.html para 404.html (Permite roteamento SPA no GitHub Pages)
Copy-Item -Path "build\web\index.html" -Destination "build\web\404.html" -Force

# Subpastas com index.html para suporte a links diretos no GitHub Pages
$subroutes = @("admin", "mestre", "studio", "creator", "player", "portal", "e", "login", "auth", "desafio")
foreach ($route in $subroutes) {
  $targetDir = "build\web\$route"
  if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  }
  Copy-Item -Path "build\web\index.html" -Destination "$targetDir\index.html" -Force
}

Write-Host "`nBuild Web finalizado com sucesso em build\web!" -ForegroundColor Green

if ($DeployGhPages) {
  Write-Host "`nPreparando deploy para a branch origin/gh-pages..." -ForegroundColor Yellow
  $currentBranch = (git branch --show-current).Trim()
  
  # Cria repositório temporário ou utiliza worktree/push direto
  $tempDeploy = "build\gh-pages-deploy"
  if (Test-Path $tempDeploy) {
    Remove-Item -Recurse -Force $tempDeploy
  }
  
  git clone --depth 1 --branch gh-pages (git config --get remote.origin.url) $tempDeploy
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Não foi possível clonar branch gh-pages diretamente. Tentando criar branch órfã..."
    New-Item -ItemType Directory -Path $tempDeploy -Force | Out-Null
    Push-Location $tempDeploy
    git init
    git checkout -b gh-pages
    git remote add origin (git config --get remote.origin.url)
    Pop-Location
  }

  # Copia arquivos construídos para a pasta de deploy
  Get-ChildItem -Path $tempDeploy -Exclude ".git" | Remove-Item -Recurse -Force
  Copy-Item -Path "build\web\*" -Destination $tempDeploy -Recurse -Force

  Push-Location $tempDeploy
  git add -A
  git commit -m "deploy: update gh-pages with Painel Mestre, Creator Studio and Player"
  git push origin gh-pages --force
  Pop-Location

  Remove-Item -Recurse -Force $tempDeploy
  Write-Host "`nDeploy para GitHub Pages concluído com sucesso!" -ForegroundColor Green
}
