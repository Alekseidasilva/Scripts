# Agendador de Eliminação de Arquivos PRIMAVERA

Script para Windows que agenda a eliminação automática de arquivos de licença do PRIMAVERA.

## 📋 Descrição

Este script agenda a eliminação anual dos seguintes arquivos:
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\Primavera.hlf`
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\PRILIC.lic`

**Data de execução:** Todo dia 01 de Janeiro (2026, 2027, 2028, etc.)
**Retry progressivo:** 3 tentativas automáticas (após 5, 10 e 15 dias)
**Busca inteligente:** Procura arquivos em múltiplas localizações automaticamente
**Auto-reparo:** Verifica e restaura a tarefa agendada se necessário

## 💻 Compatibilidade

✅ Windows 7
✅ Windows 8 / 8.1
✅ Windows 10
✅ Windows 11

## 📦 Arquivos Incluídos

1. **Install-PrimaveraCleanupTask.ps1** - Script de instalação (executar uma única vez)
2. **Delete-PrimaveraFiles.ps1** - Script principal que deleta os arquivos
3. **README-PrimaveraCleanup.md** - Este arquivo de documentação

## 🚀 Como Instalar

### Passo 1: Baixar os Scripts

Certifique-se que ambos os arquivos `.ps1` estão na mesma pasta.

### Passo 2: Executar como Administrador

1. Clique com o **botão direito** em `Install-PrimaveraCleanupTask.ps1`
2. Selecione **"Executar com PowerShell"** ou **"Executar como Administrador"**
3. Se aparecer aviso de segurança, clique em **"Executar uma vez"** ou **"Sim"**

### Passo 3: Confirmar Instalação

Você verá uma mensagem confirmando:
- Nome da tarefa criada
- Data da próxima execução
- Arquivos que serão deletados

## 🔍 Como Verificar

### Ver a Tarefa Agendada

1. Pressione `Win + R`
2. Digite `taskschd.msc` e pressione Enter
3. Procure por **"PRIMAVERA_Annual_Cleanup"** na lista

### Ver Logs e Estado

**Logs de execução:**
```
C:\ProgramData\PrimaveraCleanup\deletion_log.txt
```

**Estado de retry (JSON):**
```
C:\ProgramData\PrimaveraCleanup\retry_state.json
```

Este arquivo rastreia:
- Número da tentativa atual
- Data da última execução
- Lista de arquivos que falharam

## 📅 Funcionamento

### Execução Normal

- A tarefa roda automaticamente todo dia **01 de Janeiro às 00:05**
- **Busca inteligente**: Procura os arquivos em múltiplas localizações:
  - `C:\Program Files (x86)\PRIMAVERA\*`
  - `C:\Program Files\PRIMAVERA\*`
  - `C:\PRIMAVERA\*`
  - Subdiretórios: `SG100\Config\LP`, `Config\LP`, `Config`, etc.
- Deleta **todas as ocorrências** encontradas
- Registra o resultado no arquivo de log

### Sistema de Retry Progressivo

Se houver falhas, o sistema tenta automaticamente múltiplas vezes:

| Tentativa | Intervalo | Descrição |
|-----------|-----------|-----------|
| **1ª** | Imediato | Execução normal anual |
| **2ª** | +5 dias | Se a 1ª tentativa falhar |
| **3ª** | +10 dias | Se a 2ª tentativa falhar |
| **4ª** | +15 dias | Se a 3ª tentativa falhar |

- Salva estado em: `C:\ProgramData\PrimaveraCleanup\retry_state.json`
- Cria tarefa temporária **"PRIMAVERA_Cleanup_Retry"** para cada tentativa
- Após **3 retries sem sucesso**, registra erro crítico no log

### Verificação de Integridade

A cada execução, o script verifica:
- ✅ Se a tarefa anual **"PRIMAVERA_Annual_Cleanup"** existe
- ✅ Se a tarefa está habilitada (não foi desabilitada manualmente)
- ✅ Se necessário, **recria automaticamente** a tarefa (auto-reparo)

### Após Sucesso Total

- Remove automaticamente qualquer tarefa de retry pendente
- Limpa arquivo de estado
- Aguarda até o próximo 01 de Janeiro

## ❌ Como Desinstalar

### Opção 1: Via PowerShell (Recomendado)

Execute como Administrador:
```powershell
Unregister-ScheduledTask -TaskName "PRIMAVERA_Annual_Cleanup" -Confirm:$false
Unregister-ScheduledTask -TaskName "PRIMAVERA_Cleanup_Retry" -Confirm:$false -ErrorAction SilentlyContinue
```

### Opção 2: Via Interface Gráfica

1. Abra o Agendador de Tarefas (`Win + R` → `taskschd.msc`)
2. Localize **"PRIMAVERA_Annual_Cleanup"**
3. Clique com botão direito → **Excluir**
4. Repita para **"PRIMAVERA_Cleanup_Retry"** se existir

### Opção 3: Deletar Arquivos de Log (Opcional)

```
C:\ProgramData\PrimaveraCleanup\
```

## 🔧 Solução de Problemas

### "Não é possível executar scripts neste sistema"

Execute como Administrador:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Arquivos Não São Deletados

Possíveis causas:
- Arquivos estão em uso por outro programa (feche o PRIMAVERA)
- Permissões insuficientes (verifique se a tarefa está configurada como SYSTEM)
- Arquivos protegidos por antivírus

**Solução:** Verifique o log em `C:\ProgramData\PrimaveraCleanup\deletion_log.txt` para detalhes

### Tarefa Não Executa

1. Abra o Agendador de Tarefas
2. Localize a tarefa **"PRIMAVERA_Annual_Cleanup"**
3. Clique com botão direito → **Executar**
4. Verifique o histórico na aba **"Histórico"**

## 🎯 Funcionalidades Avançadas (v2.0)

### 1️⃣ Retry Progressivo Inteligente
- **3 tentativas automáticas** com intervalos crescentes (5, 10, 15 dias)
- Rastreamento de estado em arquivo JSON
- Desistência automática após esgotar tentativas

### 2️⃣ Busca em Múltiplas Localizações
- Suporta instalações customizadas do PRIMAVERA
- Procura em **Program Files (x86)**, **Program Files** e **C:\PRIMAVERA**
- Busca recursiva em subdiretórios se necessário
- **Deleta todas as ocorrências** encontradas

### 3️⃣ Auto-Reparo e Verificação de Integridade
- Verifica se a tarefa anual existe a cada execução
- Detecta se a tarefa foi desabilitada manualmente
- **Recria automaticamente** a tarefa se necessário
- Garante continuidade do agendamento

## 📝 Notas Importantes

- ⚠️ **Este script deleta arquivos permanentemente!** Certifique-se que você realmente deseja eliminar estes arquivos.
- 🔒 A tarefa roda com privilégios de SYSTEM para garantir acesso aos arquivos
- 📊 Todos os logs são salvos e podem ser consultados a qualquer momento
- 🔄 Sistema de retry progressivo com até **3 tentativas** automáticas
- 🔍 Busca inteligente encontra arquivos em **qualquer localização** do PRIMAVERA
- 🛠️ Auto-reparo garante que a tarefa continue funcionando mesmo se for removida
- 🗓️ A tarefa é anual, então executará automaticamente em 2026, 2027, 2028, etc.

## 🆘 Suporte

Para problemas ou dúvidas:
1. Consulte o arquivo de log
2. Verifique o histórico da tarefa no Agendador de Tarefas
3. Execute o script manualmente para testar

---

**Versão:** 2.0
**Última atualização:** Dezembro 2025
**Changelog v2.0:**
- ✨ Retry progressivo com múltiplas tentativas (5, 10, 15 dias)
- ✨ Busca automática em múltiplas localizações do PRIMAVERA
- ✨ Verificação de integridade e auto-reparo da tarefa agendada
- ✨ Sistema de estado persistente (retry_state.json)
- ✨ Logs detalhados com rastreamento de tentativas
