# Sistema de Setup de Licenciamento PRIMAVERA

## Visão Geral

Este sistema permite criar pacotes de setup autocontidos que incluem todos os arquivos de licença necessários e implementam agendamento automático de exclusão baseado no período de licença escolhido.

## 📋 Índice

1. [Características](#características)
2. [Como Criar um Setup](#como-criar-um-setup)
3. [Como Usar o Setup](#como-usar-o-setup)
4. [Períodos de Licença](#períodos-de-licença)
5. [Agendamento Automático](#agendamento-automático)
6. [Arquivos do Sistema](#arquivos-do-sistema)
7. [Fluxo de Funcionamento](#fluxo-de-funcionamento)

## ✨ Características

- **Setup Autocontido**: Todos os arquivos necessários incluídos em um único arquivo
- **Auto-Extração**: Extrai automaticamente os arquivos ao executar
- **Interface Gráfica**: GUI amigável para coletar informações do cliente
- **Validação**: Validação automática de NIF e email
- **Períodos Flexíveis**: Escolha entre 3 meses, 6 meses, 1 ano ou 2 anos
- **Exclusão Automática**: Agenda automaticamente a remoção dos arquivos de licença
- **Sistema de Retry**: Tenta novamente a cada 2 horas durante 7 dias se houver falhas
- **Logs Detalhados**: Registra todas as operações para auditoria

## 🚀 Como Criar um Setup

### Passo 1: Verificar Arquivos Necessários

Certifique-se que os seguintes arquivos estão no repositório:

- ✅ `Primavera.hlf` - Arquivo de licença principal
- ✅ `PRILIC.lic` - Arquivo de licença secundário
- ✅ `LICENCIAR.bat` - Iniciador do sistema
- ✅ `License-Primavera.ps1` - Script principal de licenciamento
- ✅ `Delete-IndividualLicense.ps1` - Script de exclusão de licença

### Passo 2: Executar o Gerador de Setup

#### Opção 1: Usando o arquivo BAT (Recomendado)

1. Clique com botão direito em `CRIAR-SETUP.bat`
2. Selecione "Executar como Administrador"
3. (Opcional) Digite o nome do cliente para personalizar
4. Aguarde a geração do setup

#### Opção 2: Usando PowerShell Diretamente

```powershell
# Setup genérico
.\Create-LicenseSetup.ps1

# Setup personalizado para cliente
.\Create-LicenseSetup.ps1 -ClientName "Nome do Cliente" -OutputPath "C:\Setups\ClienteX-Setup.ps1"
```

### Passo 3: Distribuir o Setup

O arquivo gerado `SETUP-LICENCIAMENTO-PRIMAVERA.ps1` está pronto para distribuição.

**Tamanho típico**: ~30-50 KB (compactado e codificado em Base64)

## 💻 Como Usar o Setup

### Para o Técnico/Cliente:

1. **Receber o arquivo** `SETUP-LICENCIAMENTO-PRIMAVERA.ps1`

2. **Executar como Administrador**:
   - Clique com botão direito no arquivo
   - Selecione "Executar com PowerShell"
   - Ou execute via PowerShell:
     ```powershell
     .\SETUP-LICENCIAMENTO-PRIMAVERA.ps1
     ```

3. **Preencher o Formulário**:
   - Nome da Empresa (obrigatório)
   - NIF (9 dígitos, validado automaticamente)
   - Email (validado automaticamente)
   - Morada
   - **Período de Licença** (escolher uma opção)

4. **Confirmar**:
   - Clique em "Licenciar"
   - Aguarde a cópia dos arquivos
   - Aguarde a confirmação

5. **Conclusão**:
   - Os arquivos de licença serão copiados para o sistema PRIMAVERA
   - A exclusão automática será agendada
   - Uma mensagem de sucesso será exibida

## ⏰ Períodos de Licença

| Período | Duração | Dias |
|---------|---------|------|
| 3 meses | 90 dias | 90 |
| 6 meses | 180 dias | 180 |
| 1 ano | 365 dias | 365 |
| 2 anos | 730 dias | 730 |

## 🔄 Agendamento Automático

### Como Funciona

1. **No Momento do Licenciamento**:
   - O sistema calcula a data de expiração baseado no período escolhido
   - Cria uma tarefa agendada no Windows: `PRIMAVERA_License_Expiry_LIC-XXXX`
   - A tarefa executará `Delete-IndividualLicense.ps1` na data de expiração

2. **Na Data de Expiração**:
   - A tarefa agendada é executada automaticamente
   - O script procura os arquivos de licença em todos os locais possíveis
   - Remove os arquivos: `Primavera.hlf` e `PRILIC.lic`
   - Atualiza o log e o banco de dados de licenças

3. **Sistema de Retry** (em caso de falha):
   - Se houver falha na exclusão (arquivo em uso, permissões, etc.)
   - O sistema tenta novamente a cada 2 horas
   - Continua tentando por até 7 dias
   - Após 7 dias, registra erro crítico e para de tentar

4. **Após Sucesso**:
   - Remove a tarefa agendada
   - Atualiza o histórico da licença
   - Registra no log

### Verificar Tarefas Agendadas

```powershell
# Listar todas as tarefas de licenças PRIMAVERA
Get-ScheduledTask | Where-Object { $_.TaskName -like "PRIMAVERA_License_*" }

# Ver detalhes de uma tarefa específica
Get-ScheduledTask -TaskName "PRIMAVERA_License_Expiry_LIC-0001" | Format-List *
```

### Cancelar Agendamento (Manual)

```powershell
# Remover tarefa de uma licença específica
Unregister-ScheduledTask -TaskName "PRIMAVERA_License_Expiry_LIC-0001" -Confirm:$false
```

## 📁 Arquivos do Sistema

### Arquivos Principais

| Arquivo | Descrição |
|---------|-----------|
| `CRIAR-SETUP.bat` | Iniciador do gerador de setup (interface amigável) |
| `Create-LicenseSetup.ps1` | Script que gera o setup autocontido |
| `LICENCIAR.bat` | Iniciador do sistema de licenciamento |
| `License-Primavera.ps1` | Script principal de licenciamento |
| `Delete-IndividualLicense.ps1` | Script de exclusão de licença individual |
| `Primavera.hlf` | Arquivo de licença principal |
| `PRILIC.lic` | Arquivo de licença secundário |

### Arquivos de Saída

| Arquivo/Diretório | Descrição |
|-------------------|-----------|
| `SETUP-LICENCIAMENTO-PRIMAVERA.ps1` | Setup gerado (autocontido) |
| `C:\PrimaveraLicenseVault\` | Diretório principal do sistema |
| `C:\PrimaveraLicenseVault\Database\` | Banco de dados de licenças |
| `C:\PrimaveraLicenseVault\Logs\` | Logs do sistema |
| `C:\PrimaveraLicenseVault\Backups\` | Backups dos arquivos |
| `C:\PrimaveraLicenseVault\DeletionState\` | Estados de retry de exclusão |

### Locais de Instalação dos Arquivos de Licença

O sistema copia os arquivos para os seguintes locais (se existirem):

- `C:\Program Files (x86)\PRIMAVERA\SG100\Config\LP\`
- `C:\Program Files\PRIMAVERA\SG100\Config\LP\`

## 🔄 Fluxo de Funcionamento

### 1. Criação do Setup

```
[Técnico/Administrador]
    │
    ├─> Executa CRIAR-SETUP.bat (como Admin)
    │
    ├─> Create-LicenseSetup.ps1 é executado
    │   │
    │   ├─> Verifica arquivos obrigatórios
    │   ├─> Compacta arquivos em ZIP
    │   ├─> Codifica ZIP em Base64
    │   └─> Gera SETUP-LICENCIAMENTO-PRIMAVERA.ps1
    │
    └─> Distribui o setup para cliente/técnico
```

### 2. Execução do Setup

```
[Cliente/Técnico em Campo]
    │
    ├─> Executa SETUP-LICENCIAMENTO-PRIMAVERA.ps1 (como Admin)
    │
    ├─> Setup Auto-Extrai Arquivos
    │   │
    │   ├─> Cria pasta temporária
    │   ├─> Decodifica Base64
    │   ├─> Extrai ZIP
    │   └─> Executa LICENCIAR.bat
    │
    ├─> LICENCIAR.bat executa License-Primavera.ps1
    │
    ├─> GUI de Licenciamento
    │   │
    │   ├─> Coleta dados do cliente
    │   ├─> Valida NIF e Email
    │   └─> Técnico escolhe período (3m/6m/1a/2a)
    │
    ├─> Processamento
    │   │
    │   ├─> Gera ID de licença (LIC-XXXX)
    │   ├─> Calcula data de expiração
    │   ├─> Copia Primavera.hlf e PRILIC.lic
    │   ├─> Agenda exclusão automática
    │   └─> Salva no banco de dados
    │
    └─> Conclusão
        │
        ├─> Exibe mensagem de sucesso
        ├─> Opcionalmente limpa arquivos temporários
        └─> Sistema PRIMAVERA está licenciado
```

### 3. Expiração Automática

```
[Data de Expiração]
    │
    ├─> Tarefa Agendada dispara
    │
    ├─> Delete-IndividualLicense.ps1 é executado
    │
    ├─> Busca arquivos de licença
    │   │
    │   ├─> C:\Program Files (x86)\PRIMAVERA\...\Primavera.hlf
    │   ├─> C:\Program Files (x86)\PRIMAVERA\...\PRILIC.lic
    │   └─> (busca recursiva em todos os locais possíveis)
    │
    ├─> Tenta Deletar
    │   │
    │   ├─> Sucesso?
    │   │   │
    │   │   ├─> SIM: Remove tarefa agendada
    │   │   │       Atualiza banco de dados
    │   │   │       Registra no log
    │   │   │       FIM
    │   │   │
    │   │   └─> NÃO: Agenda retry em 2 horas
    │   │           (continua por até 7 dias)
    │   │
    │   └─> Após 7 dias de tentativas
    │       │
    │       └─> Registra erro crítico
    │           Para de tentar
    │           Mantém log para análise
```

## 📊 Banco de Dados de Licenças

Localização: `C:\PrimaveraLicenseVault\Database\licenses.json`

### Estrutura

```json
{
  "version": "1.0",
  "lastLicenseId": 5,
  "licenses": [
    {
      "licenseId": "LIC-0001",
      "client": {
        "companyName": "Empresa Exemplo Lda",
        "nif": "123456789",
        "email": "contato@empresa.pt",
        "address": "Rua Exemplo, 123\nLisboa"
      },
      "licensing": {
        "startDate": "2024-01-15T10:30:00Z",
        "period": "1a",
        "periodLabel": "1 ano",
        "periodDays": 365,
        "expiryDate": "2025-01-15T10:30:00Z",
        "autoRemove": true
      },
      "files": [
        {
          "name": "Primavera.hlf",
          "targetPath": "C:\\Program Files (x86)\\PRIMAVERA\\SG100\\Config\\LP\\Primavera.hlf",
          "hash": "SHA256:abc123...",
          "timestamp": "2024-01-15T10:30:15Z"
        }
      ],
      "history": [
        {
          "action": "LICENSED",
          "date": "2024-01-15T10:30:00Z",
          "user": "TecnicoX",
          "details": "Licenca criada. Periodo: 1 ano"
        },
        {
          "action": "EXPIRED",
          "date": "2025-01-15T10:30:00Z",
          "user": "SYSTEM",
          "details": "Licenca expirada automaticamente. Arquivos removidos."
        }
      ]
    }
  ]
}
```

## 🔒 Segurança

### Proteção dos Arquivos Master

- Arquivos `Primavera.hlf` e `PRILIC.lic` são marcados como:
  - **Hidden** (Ocultos)
  - **ReadOnly** (Somente leitura)
- Todos os arquivos do pacote (exceto LICENCIAR.bat) são protegidos
- Reduz o risco de modificação ou exclusão acidental

### Validações

- **NIF**: Algoritmo de validação de NIF português (9 dígitos)
- **Email**: Validação de formato de email
- **Campos Obrigatórios**: Todos os campos são validados antes de prosseguir

### Logs de Auditoria

- Todas as operações são registradas
- Localização: `C:\PrimaveraLicenseVault\Logs\licensing.log`
- Inclui: timestamps, ações, usuários, detalhes

## ❓ Solução de Problemas

### Setup não executa

**Problema**: "Execução de scripts está desabilitada neste sistema"

**Solução**:
```powershell
# Executar como Administrador
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\SETUP-LICENCIAMENTO-PRIMAVERA.ps1
```

### Arquivos não são copiados

**Problema**: Diretório PRIMAVERA não encontrado

**Verificar**:
1. PRIMAVERA está instalado?
2. Verificar caminhos em `License-Primavera.ps1`
3. Ver logs em `C:\PrimaveraLicenseVault\Logs\`

### Exclusão não acontece

**Problema**: Arquivos não foram removidos na data de expiração

**Verificar**:
1. Tarefa agendada existe?
   ```powershell
   Get-ScheduledTask -TaskName "PRIMAVERA_License_Expiry_*"
   ```
2. Ver logs de exclusão:
   ```powershell
   Get-Content "C:\PrimaveraLicenseVault\Logs\deletion_log.txt" -Tail 50
   ```
3. Verificar estado de retry:
   ```powershell
   Get-ChildItem "C:\PrimaveraLicenseVault\DeletionState\"
   ```

### Erro ao criar tarefa agendada

**Problema**: "Access denied" ao criar tarefa

**Solução**: Executar como Administrador

## 📞 Suporte

Para problemas ou dúvidas:

1. Verificar logs em `C:\PrimaveraLicenseVault\Logs\`
2. Consultar este README
3. Contactar suporte técnico

---

**Última atualização**: Dezembro 2024
**Versão do Sistema**: 2.0
