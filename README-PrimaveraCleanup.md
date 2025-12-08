# Agendador de Eliminação de Arquivos PRIMAVERA

Script para Windows que agenda a eliminação automática de arquivos de licença do PRIMAVERA.

## 📋 Descrição

Este script agenda a eliminação anual dos seguintes arquivos:
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\Primavera.hlf`
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\PRILIC.lic`

**Data de execução:** Todo dia 01 de Janeiro às 10:00 (2026, 2027, 2028, etc.)
**Retry inteligente:** A cada 2 horas durante 15 dias se houver falhas
**Busca inteligente:** Procura arquivos em múltiplas localizações automaticamente
**Desativação automática:** Tarefa se desativa sozinha após eliminação bem-sucedida

## 💻 Compatibilidade

✅ Windows 7
✅ Windows 8 / 8.1
✅ Windows 10
✅ Windows 11

## 📦 Arquivos Incluídos

1. **INSTALAR.bat** ⭐ - Atalho para instalação (duplo clique)
2. **DESINSTALAR.bat** - Atalho para desinstalação (duplo clique)
3. **Install-PrimaveraCleanupTask.ps1** - Script PowerShell de instalação
4. **Delete-PrimaveraFiles.ps1** - Script principal que deleta os arquivos
5. **README-PrimaveraCleanup.md** - Este arquivo de documentação

## 🚀 Como Instalar

### ⚡ Método Rápido (Recomendado)

1. **Clique com botão direito** em `INSTALAR.bat`
2. Selecione **"Executar como Administrador"**
3. Confirme o UAC (controle de conta de usuário)
4. Aguarde a mensagem de sucesso

**✨ É isso! A instalação está completa.**

### 📋 Método Alternativo (PowerShell)

Se preferir executar o script PowerShell diretamente:

1. Clique com o **botão direito** em `Install-PrimaveraCleanupTask.ps1`
2. Selecione **"Executar com PowerShell"** ou **"Executar como Administrador"**
3. Se aparecer aviso de segurança, clique em **"Executar uma vez"** ou **"Sim"**

### ✅ Confirmação de Instalação

Após a instalação, você verá:
- ✓ Nome da tarefa criada
- ✓ Data da próxima execução (01/01/2026)
- ✓ Arquivos que serão deletados
- ✓ Sistema de retry progressivo configurado

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
- Data/hora da primeira tentativa
- Data/hora da última tentativa
- Número total de tentativas realizadas
- Lista de arquivos que falharam

## 📅 Funcionamento

### Execução Normal

- A tarefa roda automaticamente todo dia **01 de Janeiro às 10:00**
- **Busca inteligente**: Procura os arquivos em múltiplas localizações:
  - `C:\Program Files (x86)\PRIMAVERA\*`
  - `C:\Program Files\PRIMAVERA\*`
  - `C:\PRIMAVERA\*`
  - Subdiretórios: `SG100\Config\LP`, `Config\LP`, `Config`, etc.
- Deleta **todas as ocorrências** encontradas
- Registra o resultado no arquivo de log
- **Desativa a tarefa automaticamente** após sucesso

### Sistema de Retry Inteligente

Se houver falhas, o sistema tenta automaticamente a cada 2 horas:

**Exemplo de sequência de tentativas no dia 01/01/2026:**

| Hora | Status | Próxima Ação |
|------|--------|--------------|
| **10:00** | Falha na deleção | Agenda retry para 12:00 |
| **12:00** | Falha novamente | Agenda retry para 14:00 |
| **14:00** | Falha novamente | Agenda retry para 16:00 |
| **16:00** | Falha novamente | Agenda retry para 18:00 |
| **...** | Continua a cada 2h | Até completar 15 dias |
| **16/01** | Fim do período | Registra erro crítico |

**Características:**
- ✅ Intervalo: **2 horas** entre tentativas
- ✅ Período máximo: **15 dias** a partir de 01/01
- ✅ Tentativas ilimitadas dentro do período
- ✅ Horários: 10h, 12h, 14h, 16h, 18h, 20h, 22h, 00h, 02h, 04h, 06h, 08h...
- ✅ Salva estado em: `C:\ProgramData\PrimaveraCleanup\retry_state.json`
- ✅ Cria tarefa temporária **"PRIMAVERA_Cleanup_Retry"** para cada tentativa

### Verificação de Integridade

A cada execução, o script verifica:
- ✅ Se a tarefa anual **"PRIMAVERA_Annual_Cleanup"** existe
- ✅ Se a tarefa está habilitada (não foi desabilitada manualmente)
- ✅ Se necessário, **recria automaticamente** a tarefa (auto-reparo)

### Após Sucesso Total

- ✅ Remove automaticamente qualquer tarefa de retry pendente
- ✅ Limpa arquivo de estado
- ✅ **DESATIVA a tarefa anual automaticamente**
- ✅ Registra no log que a tarefa foi desativada
- ℹ️ A tarefa permanece desativada e não executará mais nos próximos anos

## ❌ Como Desinstalar

### ⚡ Método Rápido (Recomendado)

1. **Clique com botão direito** em `DESINSTALAR.bat`
2. Selecione **"Executar como Administrador"**
3. Confirme quando perguntado
4. Escolha se deseja deletar os logs

**✨ Pronto! Tudo foi removido.**

### 📋 Opção 2: Via PowerShell

Execute como Administrador:
```powershell
Unregister-ScheduledTask -TaskName "PRIMAVERA_Annual_Cleanup" -Confirm:$false
Unregister-ScheduledTask -TaskName "PRIMAVERA_Cleanup_Retry" -Confirm:$false -ErrorAction SilentlyContinue
```

### 📋 Opção 3: Via Interface Gráfica

1. Abra o Agendador de Tarefas (`Win + R` → `taskschd.msc`)
2. Localize **"PRIMAVERA_Annual_Cleanup"**
3. Clique com botão direito → **Excluir**
4. Repita para **"PRIMAVERA_Cleanup_Retry"** se existir

### 🗑️ Deletar Logs Manualmente

Se não usou o desinstalador automático:
```
C:\ProgramData\PrimaveraCleanup\
```

## 🔧 Solução de Problemas

### "Arquivo .ps1 abre no Bloco de Notas ao clicar"

**Solução:** Isso é normal no Windows por segurança. Use uma das opções:

1. **Opção mais fácil:** Use o arquivo `INSTALAR.bat` (duplo clique)
2. **Opção 2:** Clique com **botão direito** no `.ps1` → **"Executar com PowerShell"**
3. **Opção 3:** Clique com **botão direito** → **"Executar como Administrador"**

### "Não é possível executar scripts neste sistema"

Execute como Administrador:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Nota:** O arquivo `INSTALAR.bat` já contorna esse problema automaticamente.

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

## 🎯 Funcionalidades Avançadas (v3.0)

### 1️⃣ Retry Inteligente a Cada 2 Horas
- **Tentativas ilimitadas** a cada 2 horas durante 15 dias
- Primeira tentativa: **01/01 às 10:00**
- Retries: **12:00, 14:00, 16:00, 18:00...** (continuamente)
- Rastreamento de estado em arquivo JSON
- Desistência automática após 15 dias

### 2️⃣ Busca em Múltiplas Localizações
- Suporta instalações customizadas do PRIMAVERA
- Procura em **Program Files (x86)**, **Program Files** e **C:\PRIMAVERA**
- Busca recursiva em subdiretórios se necessário
- **Deleta todas as ocorrências** encontradas

### 3️⃣ Desativação Automática
- **Desativa a tarefa anual** assim que deletar com sucesso
- Impede execuções futuras desnecessárias
- Economia de recursos do sistema
- Conclusão definitiva da operação

### 4️⃣ Auto-Reparo e Verificação de Integridade
- Verifica se a tarefa anual existe a cada execução
- Detecta se a tarefa foi desabilitada manualmente
- **Recria automaticamente** a tarefa se necessário
- Garante continuidade do agendamento

## 📝 Notas Importantes

- ⚠️ **Este script deleta arquivos permanentemente!** Certifique-se que você realmente deseja eliminar estes arquivos.
- 🔒 A tarefa roda com privilégios de SYSTEM para garantir acesso aos arquivos
- 📊 Todos os logs são salvos e podem ser consultados a qualquer momento
- 🔄 Sistema de retry a cada **2 horas** durante **15 dias**
- 🔍 Busca inteligente encontra arquivos em **qualquer localização** do PRIMAVERA
- 🛠️ Auto-reparo garante que a tarefa continue funcionando mesmo se for removida
- 🎯 Desativação automática após sucesso - sem execuções futuras desnecessárias
- 🗓️ A tarefa é anual, então executará automaticamente em 2026, 2027, 2028, etc.

## 🆘 Suporte

Para problemas ou dúvidas:
1. Consulte o arquivo de log
2. Verifique o histórico da tarefa no Agendador de Tarefas
3. Execute o script manualmente para testar

---

**Versão:** 3.0
**Última atualização:** Dezembro 2025

**Changelog v3.0:**
- 🚀 Retry a cada 2 horas (ao invés de dias)
- 🚀 Horário de início: 10:00 (ao invés de 00:05)
- 🚀 Período de retry: 15 dias contínuos
- 🚀 Desativação automática da tarefa após sucesso
- 🚀 Tentativas ilimitadas dentro do período de 15 dias

**Changelog v2.1:**
- 🚀 Arquivos .bat para instalação/desinstalação com um clique
- 📝 Desinstalador automático com opção de remover logs
- 📚 Instruções simplificadas no README

**Changelog v2.0:**
- ✨ Busca automática em múltiplas localizações do PRIMAVERA
- ✨ Verificação de integridade e auto-reparo da tarefa agendada
- ✨ Sistema de estado persistente (retry_state.json)
- ✨ Logs detalhados com rastreamento de tentativas
