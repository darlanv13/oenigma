# Diretrizes e Regras do Projeto O Enigma

## 1. Cloud Code (Back4App / B4A)
* **Regra Obrigatória:** Sempre que qualquer arquivo dentro do diretório `b4a-cloud/` (especialmente `b4a-cloud/cloud/main.js`, `admin.js`, `financial_service.js`) for criado, modificado ou atualizado, você **DEVE** realizar o deploy imediato no Back4App executando:
  ```powershell
  cd b4a-cloud
  b4a deploy
  ```
  *(Nota: no ambiente Windows, execute o comando com `BypassSandbox: true` para que o binário `b4a.exe` em `C:\Windows\system32\b4a.exe` acesse a rede e execute sem conflito de realocação de memória).*

---

## 2. Padrão de Design Visual & UI Tokens
* **Dark Obsidian & Nobre:**
  * Background Primário: `#0B1115` / `#090D11`
  * Cards e Superfícies: `#131D24` / `#0F1519`
  * Bordas: `#1E3A45` (espessura 1.2px)
  * Dourado Nobre: `#F3A522` / `AppColors.amareloVale`
  * Verde Vale: `#007D8A` / `#00A896` / `Colors.greenAccent`
* **Tipografia:**
  * Títulos e Cabeçalhos: `GoogleFonts.cinzel`
  * Métricas, Códigos e Cronômetros: `GoogleFonts.orbitron`
  * Textos Corridos e Legendas: `GoogleFonts.inter` ou `GoogleFonts.poppins`

---

## 3. Deploy Web e GitHub Pages
* Para compilar a aplicação Web (App Cliente e Painel Admin Web) sem quebra de glifos do FontAwesome:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts\build_web.ps1 -DeployStaging
  ```
* Sincronizar as alterações compiladas no branch `gh-pages` dentro de `build\gh-pages-staging\`.
