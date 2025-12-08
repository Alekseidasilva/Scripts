# Sistema de Gestão de Licenças PRIMAVERA

Sistema completo profissional para licenciamento e gestão de clientes PRIMAVERA.

## 📋 Descrição

Este sistema permite licenciar clientes do PRIMAVERA instalando os arquivos de licença e agendando automaticamente a remoção quando o período expirar.

**Funcionalidades principais:**
- ✅ Licenciamento com coleta completa de dados do cliente
- ✅ Validação de NIF português (algoritmo oficial)
- ✅ Períodos flexíveis: 3 meses, 6 meses, 1 ano, 2 anos
- ✅ Agendamento automático de expiração
- ✅ Base de dados com histórico completo
- ✅ Consulta de licenças ativas
- ✅ Renovação de licenças
- ✅ Interface gráfica profissional

## 💻 Compatibilidade

✅ Windows 7
✅ Windows 8 / 8.1
✅ Windows 10
✅ Windows 11

## 📦 Arquivos do Sistema

### Scripts de Licenciamento
1. **LICENCIAR.bat** ⭐ - Criar nova licença (duplo clique)
2. **CONSULTAR-LICENCAS.bat** 📊 - Ver licenças ativas
3. **RENOVAR-LICENCA.bat** 🔄 - Renovar licença existente

### Scripts PowerShell
4. **License-Primavera.ps1** - Motor de licenciamento
5. **View-Licenses.ps1** - Visualização de licenças
6. **Renew-License.ps1** - Renovação de licenças

### Integração com Remoção
7. **Delete-PrimaveraFiles.ps1** - Remove arquivos (já existe)
8. **Install-PrimaveraCleanupTask.ps1** - Instalador de remoção (já existe)

## 🚀 Configuração Inicial

### Passo 1: Preparar Arquivos Master

Os arquivos de licença já acompanham este pacote e são usados diretamente daqui, sem cópia para `C:\PrimaveraLicenseVault`. Confirme que eles estão na mesma pasta que os scripts:

```
[PastaDoPacote]\
├── Primavera.hlf   (arquivo master do pacote)
└── PRILIC.lic      (arquivo master do pacote)
```

**IMPORTANTE:** Se algum arquivo master estiver ausente, adicione-o ao pacote antes de executar o licenciamento.

### Passo 2: Verificar Estrutura

O sistema criará automaticamente apenas a estrutura de apoio para base, backups e logs:

```
C:\PrimaveraLicenseVault\
├── Database\           (base de dados - AUTO)
│   └── licenses.json
├── Backups\            (backups automáticos - AUTO)
│   └── [data_hora]\
└── Logs\               (logs de operações - AUTO)
    └── licensing.log
```

## 📝 Como Licenciar um Cliente

### Método Rápido (Recomendado)

1. **Clique com botão direito** em `LICENCIAR.bat`
2. Selecione **"Executar como Administrador"**
3. Preencha o formulário:
   - Nome da Empresa
   - NIF (9 dígitos - validação automática)
   - Email
   - Morada
   - Período (3m, 6m, 1a, 2a)
4. Clique em **"Licenciar"**
5. ✅ Pronto! Cliente licenciado

### O Que Acontece Automaticamente:

✅ Arquivos copiados para o PRIMAVERA
✅ Registro criado na base de dados
✅ Tarefa agendada para remover na data de expiração
✅ Backup dos arquivos criado
✅ Log de operação gerado

## 📊 Consultar Licenças

### Ver Todas as Licenças

1. Duplo clique em `CONSULTAR-LICENCAS.bat`
2. Veja a tabela com todas as licenças
3. Cores indicam status:
   - 🟢 Verde: Ativa (> 30 dias)
   - 🟡 Amarelo: Expira em breve (< 30 dias)
   - 🟠 Laranja: Expira muito em breve (< 7 dias)
   - 🔴 Vermelho: Expirada

### Ver Detalhes de uma Licença

1. Na tela de consulta, selecione uma licença
2. Clique em "Ver Detalhes"
3. Veja informações completas:
   - Dados do cliente
   - Período de licença
   - Arquivos instalados
   - Histórico de operações

## 🔄 Renovar Licença

### Como Renovar

1. **Clique com botão direito** em `RENOVAR-LICENCA.bat`
2. Selecione **"Executar como Administrador"**
3. Selecione a licença da lista
4. Escolha o período adicional (3m, 6m, 1a, 2a)
5. Clique em "Renovar"
6. ✅ Licença estendida!

### Lógica de Renovação

- Se licença ainda está ativa → adiciona período a partir da data de expiração
- Se licença já expirou → adiciona período a partir de hoje
- Tarefa agendada é automaticamente atualizada
- Histórico é registrado

## 📅 Integração com Remoção Automática

### Como Funciona

Quando você licencia um cliente:

```
Data de Licença: 15/01/2026
Período: 6 meses
Data de Expiração: 15/07/2026

↓

Sistema cria automaticamente:
Tarefa: PRIMAVERA_License_Expiry_LIC-0001
Executa em: 15/07/2026 às 10:00
Script: Delete-PrimaveraFiles.ps1
```

### Sistema de Retry na Expiração

Se a remoção falhar na data de expiração:
- ✅ Tenta novamente a cada 2 horas
- ✅ Continua tentando por 15 dias
- ✅ Logs detalhados de cada tentativa

## 💾 Base de Dados

### Estrutura (licenses.json)

```json
{
  "version": "1.0",
  "lastLicenseId": 5,
  "licenses": [
    {
      "licenseId": "LIC-0001",
      "client": {
        "companyName": "Empresa XYZ Lda",
        "nif": "501234567",
        "email": "contato@empresa.pt",
        "address": "Rua ABC, 123, Lisboa"
      },
      "licensing": {
        "startDate": "2026-01-15T10:00:00",
        "period": "1a",
        "periodLabel": "1 ano",
        "periodDays": 365,
        "expiryDate": "2027-01-15T10:00:00",
        "autoRemove": true
      },
      "files": [
        {
          "name": "Primavera.hlf",
          "sourcePath": "C:\\PacoteLicenciamento\\Primavera.hlf",
          "targetPath": "C:\\Program Files (x86)\\PRIMAVERA\\SG100\\Config\\LP\\Primavera.hlf",
          "hash": "SHA256:abc123...",
          "timestamp": "2026-01-15T10:00:00"
        }
      ],
      "history": [
        {
          "action": "LICENSED",
          "date": "2026-01-15T10:00:00",
          "user": "SYSTEM",
          "details": "Licenca criada. Periodo: 1 ano"
        },
        {
          "action": "RENEWED",
          "date": "2027-01-10T14:30:00",
          "user": "Admin",
          "details": "Licenca renovada por 1 ano. Nova expiracao: 15/01/2028"
        }
      ]
    }
  ]
}
```

### Backup da Base de Dados

**Localização:** `C:\PrimaveraLicenseVault\Database\licenses.json`

**Recomendação:** Faça backup regular deste arquivo!

```powershell
# Criar backup manual
Copy-Item "C:\PrimaveraLicenseVault\Database\licenses.json" "C:\Backup\licenses_$(Get-Date -Format 'yyyyMMdd').json"
```

## 📊 Logs e Auditoria

### Log de Licenciamento

**Arquivo:** `C:\PrimaveraLicenseVault\Logs\licensing.log`

**Exemplo:**
```
[2026-01-15 10:00:00] =========================================
[2026-01-15 10:00:00] Iniciando processo de licenciamento PRIMAVERA
[2026-01-15 10:00:01] Dados do cliente coletados: Empresa XYZ Lda (NIF: 501234567)
[2026-01-15 10:00:01] ID de Licenca: LIC-0001
[2026-01-15 10:00:01] Periodo: 1 ano (365 dias)
[2026-01-15 10:00:01] Data de Expiracao: 15/01/2027 10:00
[2026-01-15 10:00:02] Arquivo copiado: C:\Program Files (x86)\PRIMAVERA\...
[2026-01-15 10:00:03] Tarefa agendada criada: PRIMAVERA_License_Expiry_LIC-0001 para 15/01/2027 10:00
[2026-01-15 10:00:03] Licenca registrada na base de dados
[2026-01-15 10:00:03] Processo de licenciamento concluido com sucesso
```

## 🔐 Segurança e Validações

### Validação de NIF

Algoritmo completo de validação de NIF português:
- ✅ Formato: 9 dígitos
- ✅ Dígito de controle verificado matematicamente
- ✅ Rejeita NIFs inválidos

### Validação de Email

- ✅ Formato padrão RFC
- ✅ Verifica @ e domínio

### Integridade de Arquivos

- ✅ Hash SHA-256 de cada arquivo copiado
- ✅ Verificação futura possível

## 🔧 Solução de Problemas

### "Arquivos master não encontrados"

**Solução:**
1. Confirme que `Primavera.hlf` e `PRILIC.lic` estão na mesma pasta do script `License-Primavera.ps1`.
2. Se estiverem ausentes, extraia-os do repositório ou solicite novos arquivos e coloque-os no pacote antes de executar novamente.

### "Erro ao copiar arquivos"

**Causas possíveis:**
- PRIMAVERA está em execução (feche-o)
- Permissões insuficientes (execute como Admin)
- Antivírus bloqueando (adicione exceção)

### "NIF inválido"

**Solução:**
- Verifique se tem 9 dígitos
- Use um NIF português válido
- Exemplo válido: 501234567

### Tarefas Agendadas Não Aparecem

**Verificar:**
1. Abra: `Win + R` → `taskschd.msc`
2. Procure por: `PRIMAVERA_License_Expiry_*`
3. Se não existir: problema no agendamento

## 📊 Relatórios e Estatísticas

### Via Script de Consulta

Execute `CONSULTAR-LICENCAS.bat` para ver:
- Total de licenças
- Licenças ativas
- Licenças expirando em breve (7 dias)
- Licenças expiradas

### Via PowerShell Direto

```powershell
# Ver resumo rápido
$db = Get-Content "C:\PrimaveraLicenseVault\Database\licenses.json" | ConvertFrom-Json
"Total de licencas: $($db.licenses.Count)"

# Ver próximas expirações
$db.licenses | ForEach-Object {
    $expiry = [datetime]::Parse($_.licensing.expiryDate)
    $days = ($expiry - (Get-Date)).Days
    if ($days -ge 0 -and $days -le 30) {
        "$($_.licenseId) - $($_.client.companyName) - Expira em $days dias"
    }
}
```

## 🎯 Fluxo Completo do Sistema

```
┌─────────────────────────────────────────┐
│  1. LICENCIAR CLIENTE                   │
├─────────────────────────────────────────┤
│  • Coletar dados (GUI)                  │
│  • Validar NIF e email                  │
│  • Copiar arquivos master               │
│  • Criar registro na BD                 │
│  • Agendar remoção                      │
│  • Gerar logs                           │
└────────────┬────────────────────────────┘
             │
             ├──► 2. CONSULTAR LICENÇAS
             │    • Ver tabela de licenças
             │    • Filtrar por status
             │    • Ver detalhes completos
             │
             ├──► 3. RENOVAR LICENÇA
             │    • Selecionar licença
             │    • Escolher período
             │    • Atualizar expiração
             │    • Atualizar tarefa agendada
             │
             └──► 4. REMOÇÃO AUTOMÁTICA
                  • Executada na data de expiração
                  • Retry a cada 2h por 15 dias
                  • Logs detalhados
```

## 📝 Notas Importantes

- ⚠️ **Backup:** Faça backup regular da base de dados!
- 🔒 **Arquivos Master:** Guarde os originais em local seguro
- 📊 **Logs:** Consulte regularmente para auditoria
- 🔄 **Renovação:** Renove antes da expiração para evitar interrupções
- 📅 **Tarefas:** Verifique tarefas agendadas periodicamente

## 🆘 Suporte

Para problemas ou dúvidas:
1. Consulte os logs em `C:\PrimaveraLicenseVault\Logs\licensing.log`
2. Verifique a base de dados em `licenses.json`
3. Execute scripts manualmente para testar

---

**Versão:** 1.0 (Sistema Completo Profissional)
**Última atualização:** Dezembro 2025
**Compatível com:** Sistema de Remoção PRIMAVERA v3.0

**Desenvolvido para:**
- Gestão profissional de licenças
- Controle total de clientes
- Automação completa
- Rastreabilidade e auditoria
