# Executáveis (.EXE) de Licenciamento PRIMAVERA 💾

## Visão Geral

Criação de executáveis (.exe) profissionais e auto-extraíveis para distribuição fácil aos técnicos. O arquivo .exe contém todos os arquivos necessários embutidos e se auto-extrai ao executar.

## 🎯 Por que usar .EXE?

### Vantagens sobre Scripts PowerShell (.ps1)

| Característica | .EXE | .PS1 |
|----------------|------|------|
| **Aparência** | ⭐⭐⭐⭐⭐ Profissional | ⭐⭐⭐ Script |
| **Distribuição** | ✅ Um único arquivo | ⚠️ Precisa .zip |
| **Execução** | ✅ Duplo clique | ⚠️ Requer PowerShell |
| **Extração** | ✅ Automática | ⚠️ Manual |
| **Confiança** | ✅ Executável Windows | ⚠️ Script |
| **Tamanho** | ~100-200 KB | ~50-70 KB |

### Para o Técnico

✅ **Mais Fácil** - Apenas copiar e executar
✅ **Mais Rápido** - Não precisa extrair manualmente
✅ **Mais Profissional** - Parece software comercial
✅ **Menos Erros** - Extração automática
✅ **Universal** - Funciona em qualquer Windows

### Para o Administrador

✅ **Distribuição Simples** - Email, PEN drive, rede
✅ **Menos Suporte** - Técnicos não precisam ajuda
✅ **Personalização** - Nome do cliente no .exe
✅ **Rastreável** - Sabe qual versão foi distribuída

## 🚀 Como Criar Executáveis

### Método 1: Wizard (Recomendado) 🧙‍♂️

Interface profissional com 5 etapas guiadas

```batch
# Executar como Administrador
CRIAR-EXE-WIZARD.bat
```

**Resultado**: `SETUP-PRIMAVERA-WIZARD.exe` (~150-200 KB)

**Contém**:
- Interface wizard completa
- 5 etapas com navegação
- Validação em tempo real
- Barra de progresso

### Método 2: Formulário Simples 📝

Interface rápida em uma única tela

```batch
# Executar como Administrador
CRIAR-EXE-SIMPLES.bat
```

**Resultado**: `SETUP-PRIMAVERA-SIMPLES.exe` (~120-150 KB)

**Contém**:
- Formulário único
- Validação básica
- Processo rápido

## 📋 Processo de Criação

### Passo a Passo

1. **Executar Gerador**
   ```batch
   CRIAR-EXE-WIZARD.bat
   ```

2. **Informações Solicitadas** (opcionais):
   - Nome do Cliente (aparece no título do .exe)
   - Nome do arquivo .exe (padrão: SETUP-PRIMAVERA-WIZARD.exe)

3. **Aguardar Criação** (~5-10 segundos)
   - Verificação de arquivos
   - Cópia para diretório temporário
   - Geração de configuração IExpress
   - Criação do executável
   - Limpeza de arquivos temporários

4. **Arquivo Pronto!**
   - .exe criado no mesmo diretório
   - Pronto para distribuição

### Exemplo de Execução

```
========================================
GERADOR DE EXECUTAVEL (.EXE) - WIZARD
========================================

Deseja personalizar o executavel para um cliente especifico?
(Pressione Enter para pular)

Nome do Cliente: Empresa ABC Lda█

Nome do arquivo .exe a ser criado?
(Pressione Enter para usar o padrao: SETUP-PRIMAVERA-WIZARD.exe)

Nome do arquivo: Setup-EmpresaABC.exe█

Gerando executavel (.exe) com interface WIZARD...

Verificando arquivos necessarios...
  [OK] LICENCIAR-WIZARD.bat
  [OK] License-Wizard.ps1
  [OK] Delete-IndividualLicense.ps1
  [OK] Primavera.hlf
  [OK] PRILIC.lic

Todos os arquivos encontrados!

Preparando arquivos...
Criando launcher...
Gerando configuracao do IExpress...
Criando executavel (.exe)...

========================================
EXECUTAVEL CRIADO COM SUCESSO!
========================================

Arquivo gerado:
  C:\Scripts\Setup-EmpresaABC.exe

Tamanho:
  175.23 KB (0.17 MB)

Tipo de Interface:
  WIZARD - Interface profissional com 5 etapas

Arquivos incluidos:
  - LICENCIAR-WIZARD.bat
  - License-Wizard.ps1
  - Delete-IndividualLicense.ps1
  - Primavera.hlf
  - PRILIC.lic
```

## 💻 Como Usar o Executável

### Para o Técnico em Campo

1. **Copiar o .exe**
   - PEN drive
   - Email
   - Rede compartilhada
   - OneDrive/Dropbox

2. **No computador do cliente**
   - Copiar o .exe para qualquer pasta
   - Clicar com botão direito
   - "Executar como Administrador"

3. **O .exe faz automaticamente**:
   - ✅ Verifica privilégios de Administrador
   - ✅ Extrai todos os arquivos
   - ✅ Abre a interface (Wizard ou Simples)
   - ✅ Guia o processo de licenciamento
   - ✅ Instala e agenda exclusão

4. **Concluído!**
   - Licença instalada
   - Agendamento configurado
   - Arquivos podem ser mantidos ou removidos

### Fluxo de Execução

```
[Técnico executa .exe]
    ↓
[Verificação de Admin]
    ↓
    SIM → Continua
    NÃO → Tenta elevar privilégios
    ↓
[Auto-extração de arquivos]
    ↓
[Execução do launcher]
    ↓
[Interface abre (Wizard ou Simples)]
    ↓
[Técnico preenche dados]
    ↓
[Sistema instala licença]
    ↓
[Agendamento automático]
    ↓
[Conclusão]
    ↓
[Opção de manter/remover arquivos]
```

## 🔧 Tecnologia Utilizada

### IExpress (Nativo do Windows)

O sistema usa **IExpress**, uma ferramenta nativa do Windows para criar executáveis auto-extraíveis.

**Vantagens do IExpress**:
- ✅ Incluído em todas as versões do Windows
- ✅ Não precisa instalar nada adicional
- ✅ Executáveis assinados pela Microsoft
- ✅ Confiável e estável
- ✅ Suporta extração e execução automática
- ✅ Mensagens personalizáveis

**Localização**:
```
C:\Windows\System32\iexpress.exe
```

### Arquivo SED (Setup Directive)

O script gera automaticamente um arquivo `.sed` com configurações:

```ini
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
TargetName=SETUP-PRIMAVERA-WIZARD.exe
FriendlyName=Setup Wizard - Licenciamento PRIMAVERA
AppLaunched=cmd /c setup_launcher.bat

[Strings]
InstallPrompt=Deseja instalar o Sistema de Licenciamento PRIMAVERA?
FinishMessage=Setup concluido! O sistema foi extraido com sucesso.

[SourceFiles]
...
```

## 📦 Conteúdo do Executável

### Wizard (.exe com interface wizard)

```
SETUP-PRIMAVERA-WIZARD.exe
│
├─ setup_launcher.bat       (Launcher principal)
├─ LICENCIAR-WIZARD.bat     (Iniciador do wizard)
├─ License-Wizard.ps1       (Script do wizard)
├─ Delete-IndividualLicense.ps1  (Exclusão automática)
├─ Primavera.hlf            (Arquivo de licença)
└─ PRILIC.lic               (Arquivo de licença)
```

### Simples (.exe com formulário)

```
SETUP-PRIMAVERA-SIMPLES.exe
│
├─ setup_launcher.bat       (Launcher principal)
├─ LICENCIAR.bat            (Iniciador do formulário)
├─ License-Primavera.ps1    (Script do formulário)
├─ Delete-IndividualLicense.ps1  (Exclusão automática)
├─ Primavera.hlf            (Arquivo de licença)
└─ PRILIC.lic               (Arquivo de licença)
```

## 🎨 Personalização

### Nome do Cliente

```batch
# Durante a criação
Nome do Cliente: Empresa XYZ Lda

# Resultado
FriendlyName=Setup Wizard - Licenciamento PRIMAVERA - Empresa XYZ Lda
```

### Nome do Arquivo

```batch
# Durante a criação
Nome do arquivo: Licenca-Cliente-Janeiro2024.exe

# Resultado
Arquivo: Licenca-Cliente-Janeiro2024.exe
```

### Usando PowerShell Diretamente

```powershell
# Wizard personalizado
.\Create-ExecutableSetup.ps1 `
    -InterfaceType Wizard `
    -OutputPath "Setup-ClienteX.exe" `
    -ClientName "Cliente X Lda"

# Simples personalizado
.\Create-ExecutableSetup.ps1 `
    -InterfaceType Simple `
    -OutputPath "Licenca-Rapida.exe" `
    -ClientName "Departamento TI"
```

## 📊 Comparação de Formatos

| Formato | Tamanho | Distribuição | Execução | Profissionalismo |
|---------|---------|--------------|----------|------------------|
| **.exe** | 150-200 KB | ⭐⭐⭐⭐⭐ Fácil | ⭐⭐⭐⭐⭐ Duplo clique | ⭐⭐⭐⭐⭐ |
| **.ps1** | 50-70 KB | ⭐⭐⭐ Médio | ⭐⭐⭐ PowerShell | ⭐⭐⭐ |
| **.zip** | 40-60 KB | ⭐⭐ Difícil | ⭐⭐ Extrair + Executar | ⭐⭐ |

## 🔒 Segurança

### Verificação de Administrador

O .exe verifica automaticamente se está executando com privilégios de Administrador:

```batch
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Privilegios de Administrador necessarios!
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 1
)
```

### Auto-elevação

Se não tiver privilégios, tenta elevar automaticamente usando PowerShell.

### Assinatura Digital

Arquivos criados com IExpress são assinados pela Microsoft, aumentando a confiança.

## 🐛 Solução de Problemas

### Erro: "IExpress não encontrado"

**Problema**: Sistema não encontra iexpress.exe

**Solução**:
```powershell
# Verificar se existe
Test-Path "C:\Windows\System32\iexpress.exe"

# Deve retornar: True
```

**Se não existir**: Reinstalar Windows ou usar versão alternativa

### Erro: "Arquivo não foi criado"

**Problema**: IExpress falha silenciosamente

**Possíveis causas**:
1. Espaço em disco insuficiente
2. Antivírus bloqueando
3. Permissões insuficientes

**Solução**:
```batch
# Executar como Administrador
# Desativar antivírus temporariamente
# Verificar espaço em disco
```

### Aviso: "Windows protegeu seu PC"

**Problema**: SmartScreen bloqueia o .exe

**Solução para o técnico**:
1. Clicar em "Mais informações"
2. Clicar em "Executar assim mesmo"

**Solução permanente**:
- Assinar digitalmente o .exe com certificado
- Distribuir via rede corporativa confiável

### .exe não abre

**Problema**: Duplo clique não faz nada

**Soluções**:
1. Executar como Administrador (botão direito)
2. Verificar antivírus
3. Verificar se é Windows genuíno
4. Testar em outro computador

## 📁 Arquivos do Sistema

| Arquivo | Descrição | Tamanho |
|---------|-----------|---------|
| `CRIAR-EXE-WIZARD.bat` | Gerador de .exe com Wizard | ~2 KB |
| `CRIAR-EXE-SIMPLES.bat` | Gerador de .exe Simples | ~2 KB |
| `Create-ExecutableSetup.ps1` | Script gerador | ~15 KB |
| `SETUP-PRIMAVERA-WIZARD.exe` | Executável gerado (Wizard) | ~180 KB |
| `SETUP-PRIMAVERA-SIMPLES.exe` | Executável gerado (Simples) | ~140 KB |

## 🎓 Tutorial Rápido

### Para Criar

```batch
1. CRIAR-EXE-WIZARD.bat (como Admin)
2. [Enter] para nome padrão
3. [Enter] para arquivo padrão
4. Aguardar criação
5. Pronto! .exe criado
```

### Para Distribuir

```
1. Copiar .exe para PEN drive
2. Levar ao cliente
3. Copiar para desktop do cliente
4. Executar como Admin
5. Seguir wizard/formulário
```

### Para o Técnico Usar

```
1. Duplo clique no .exe
   ou
   Botão direito → Executar como Admin

2. Se aparecer SmartScreen:
   - Clicar "Mais informações"
   - Clicar "Executar assim mesmo"

3. Seguir as telas
   - Wizard: 5 etapas guiadas
   - Simples: 1 formulário

4. Pronto!
```

## 💡 Dicas e Boas Práticas

### Para Criar Executáveis

✅ **Sempre use nomes descritivos**
```
Setup-Cliente-Janeiro2024.exe  (BOM)
setup.exe                       (RUIM)
```

✅ **Inclua nome do cliente**
```
-ClientName "Empresa ABC Lda"
```

✅ **Mantenha versões organizadas**
```
C:\Setups\
  ├─ 2024-01-15_ClienteA_v1.exe
  ├─ 2024-01-20_ClienteB_v1.exe
  └─ 2024-02-01_ClienteA_v2.exe
```

✅ **Teste antes de distribuir**
- Execute em máquina virtual
- Teste com/sem privilégios Admin
- Verifique se todos os passos funcionam

### Para Distribuir

✅ **Instruções claras**
```
Email ao técnico:
  Assunto: Setup de Licenciamento - Cliente ABC
  Corpo:
    - Anexo: Setup-ClienteABC.exe
    - Executar como Administrador
    - Escolher período conforme contrato (6 meses)
    - Confirmar dados do cliente
```

✅ **Backup**
- Manter cópia do .exe distribuído
- Saber qual versão foi para qual cliente

✅ **Versionamento**
- Nomear com data ou versão
- Manter histórico de distribuição

## 🆚 Quando Usar Cada Formato

### Use .EXE quando:
- ✅ Distribuindo para técnicos externos
- ✅ Cliente final vai executar
- ✅ Quer máximo profissionalismo
- ✅ Precisa de facilidade de uso
- ✅ Ambiente corporativo formal

### Use .PS1 quando:
- ✅ Uso interno da equipe TI
- ✅ Automação via scripts
- ✅ Integração com sistemas
- ✅ Desenvolvimento/testes
- ✅ Precisa modificar código

### Use .ZIP quando:
- ✅ Apenas para backup
- ✅ Arquivamento
- ✅ Transferência entre desenvolvedores

## 📞 Suporte

### Para problemas na criação:
1. Verificar se é Administrador
2. Verificar se todos os arquivos existem
3. Ver mensagens de erro específicas
4. Testar criar .ps1 antes (mais simples)

### Para problemas de execução:
1. Executar como Administrador
2. Verificar SmartScreen
3. Desativar antivírus temporariamente
4. Testar em outro computador

---

**Versão**: 1.0
**Última Atualização**: Dezembro 2024
**Tecnologia**: IExpress (Windows nativo)
**Compatibilidade**: Windows 7+
