# Agendador de Eliminação de Arquivos PRIMAVERA

Script para Windows que agenda a eliminação automática de arquivos de licença do PRIMAVERA.

## 📋 Descrição

Este script agenda a eliminação anual dos seguintes arquivos:
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\Primavera.hlf`
- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\PRILIC.lic`

**Data de execução:** Todo dia 01 de Janeiro (2026, 2027, 2028, etc.)
**Retry automático:** Se falhar, tenta novamente após 5 dias

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

### Ver Logs de Execução

Os logs são salvos em:
```
C:\ProgramData\PrimaveraCleanup\deletion_log.txt
```

## 📅 Funcionamento

### Execução Normal

- A tarefa roda automaticamente todo dia **01 de Janeiro às 00:05**
- Deleta os arquivos especificados
- Registra o resultado no arquivo de log

### Se Houver Falha

- O script detecta que houve falha na eliminação
- Agenda automaticamente uma nova tentativa para **5 dias depois**
- Cria tarefa temporária chamada **"PRIMAVERA_Cleanup_Retry"**
- Registra a falha no log

### Após Sucesso

- Remove automaticamente qualquer tarefa de retry pendente
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

## 📝 Notas Importantes

- ⚠️ **Este script deleta arquivos permanentemente!** Certifique-se que você realmente deseja eliminar estes arquivos.
- 🔒 A tarefa roda com privilégios de SYSTEM para garantir acesso aos arquivos
- 📊 Todos os logs são salvos e podem ser consultados a qualquer momento
- 🔄 O retry automático garante que falhas temporárias sejam resolvidas
- 🗓️ A tarefa é anual, então executará automaticamente em 2026, 2027, 2028, etc.

## 🆘 Suporte

Para problemas ou dúvidas:
1. Consulte o arquivo de log
2. Verifique o histórico da tarefa no Agendador de Tarefas
3. Execute o script manualmente para testar

---

**Versão:** 1.1
**Última atualização:** Dezembro 2025
