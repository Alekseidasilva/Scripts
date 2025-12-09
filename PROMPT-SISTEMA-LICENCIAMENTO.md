# PROMPT: Sistema de Licenciamento Temporário PRIMAVERA

## Contexto e Objetivo

Você é um assistente especializado em criar sistemas de licenciamento temporário para o software PRIMAVERA ERP. Seu objetivo é desenvolver um sistema completo que permita técnicos licenciarem temporariamente instalações do PRIMAVERA em computadores de clientes, com expiração automática das licenças.

## Requisitos Funcionais

### 1. Sistema de Licenciamento com Interface Gráfica

Crie duas interfaces para licenciamento:

#### Interface Wizard (Profissional - 5 Etapas):
- **Etapa 1 - Boas-vindas**: Tela inicial com logo e introdução
- **Etapa 2 - Período**: Seleção do período de licença (15, 30, 60, 90, 180 ou 365 dias)
- **Etapa 3 - Dados do Cliente**: Formulário com Nome, NIF (com validação), Telefone e Email
- **Etapa 4 - Confirmação**: Resumo de todas as informações antes da instalação
- **Etapa 5 - Conclusão**: Confirmação da instalação com detalhes da expiração

**Design da Interface:**
- Cores: Verde escuro (#1B5E20) para header/footer, branco para conteúdo
- Fonte: Segoe UI, 10pt para texto, 16pt bold para títulos
- Tamanho: 700x550 pixels
- Botões: Anterior, Próximo, Cancelar com navegação inteligente
- Validações em tempo real com mensagens claras

#### Interface Simples (Formulário Único):
- Uma única tela com todos os campos
- Mesmo esquema de cores e validações
- Mais rápida para técnicos experientes

### 2. Validação de NIF (Número de Identificação Fiscal Português)

Implemente algoritmo completo de validação de NIF:
- Verificar se tem exatamente 9 dígitos
- Validar que primeiro dígito está entre 1-3, 5, 6, 8 ou 9
- Calcular dígito de controle usando algoritmo módulo 11:
  - Multiplicar cada dígito por (9, 8, 7, 6, 5, 4, 3, 2)
  - Somar resultados e calcular módulo 11
  - Verificar se dígito de controle é válido

### 3. Gestão de Arquivos de Licença

**Arquivos a Processar:**
- `Primavera.hlf` - Arquivo de licença principal
- `PRILIC.lic` - Arquivo de configuração de licença

**Localizações de Instalação (prioridade):**
1. `C:\Program Files (x86)\Common Files\PRIMAVERA`
2. `C:\Program Files\Common Files\PRIMAVERA`
3. Busca recursiva em ambos os diretórios Program Files

**Operações Necessárias:**
- Backup automático de licenças existentes (adicionar `.bak` com timestamp)
- Cópia dos novos arquivos de licença
- Aplicar atributos: Hidden + ReadOnly para proteção
- Calcular hash SHA256 para verificação de integridade

### 4. Base de Dados de Licenças

Implementar sistema JSON em `C:\PrimaveraLicenseVault\Database\licenses.json`

**Estrutura do Registro:**
```json
{
  "LicenseId": "GUID único",
  "ClientName": "Nome do Cliente",
  "NIF": "123456789",
  "Phone": "912345678",
  "Email": "cliente@example.com",
  "InstallDate": "2024-01-15T10:30:00",
  "ExpiryDate": "2024-02-14T23:59:59",
  "DaysLicensed": 30,
  "TechnicianUser": "DOMAIN\\Username",
  "ComputerName": "DESKTOP-ABC123",
  "InstallPaths": ["C:\\Program Files\\..."],
  "FileHashes": {
    "Primavera.hlf": "SHA256...",
    "PRILIC.lic": "SHA256..."
  },
  "Status": "Active",
  "CreatedBy": "Interface type (Wizard/Form)"
}
```

### 5. Sistema de Expiração Automática

#### Expiração Individual (Delete-IndividualLicense.ps1):
- Disparado por tarefa agendada para cada licença específica
- Data/hora: Exatamente no momento da expiração
- Busca arquivos em múltiplas localizações
- Remove apenas licenças com hash correspondente ao instalado
- **Lógica de Retry Inteligente:**
  - Se falhar: tentar novamente a cada 2 horas
  - Período de retry: 7 dias após expiração
  - Estado persistido em: `C:\PrimaveraLicenseVault\RetryState\{LicenseId}.json`
  - Após 7 dias: desistir e marcar como "Expired-Failed"

#### Limpeza Anual (Delete-PrimaveraFiles.ps1):
- Tarefa agendada: 31 de Dezembro às 23:59 todo ano
- Remove TODAS as licenças do sistema
- Limpeza completa da base de dados
- Log detalhado em `C:\PrimaveraLicenseVault\Logs\AnnualCleanup-{Year}.log`

### 6. Geradores de Executáveis

#### Gerador .EXE com IExpress (Create-ExecutableSetup.ps1):

**Arquivos Incluídos (Wizard):**
- LICENCIAR-WIZARD.bat (launcher)
- License-Wizard.ps1
- Delete-IndividualLicense.ps1
- Primavera.hlf
- PRILIC.lic

**Arquivos Incluídos (Simples):**
- LICENCIAR.bat (launcher)
- License-Primavera.ps1
- Delete-IndividualLicense.ps1
- Primavera.hlf
- PRILIC.lic

**Configuração IExpress (.SED file):**
```
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
RebootMode=N

[Strings]
FILE0="setup_launcher.bat"
FILE1="LICENCIAR-WIZARD.bat"
FILE2="License-Wizard.ps1"
FILE3="Delete-IndividualLicense.ps1"
FILE4="Primavera.hlf"
FILE5="PRILIC.lic"

[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
%FILE3%=
%FILE4%=
%FILE5%=
```

**Pontos Críticos:**
- Arquivo .SED deve ser UTF-8 sem BOM
- Launcher .BAT deve ser ANSI (Default encoding)
- Verificação de privilégios de administrador embutida
- Executar com: `iexpress.exe /N "setup.sed"`

#### Gerador .PS1 Auto-Extraível (Create-WizardSetup.ps1):
- Arquivos embutidos em Base64
- Extração automática em diretório temporário
- Limpeza após execução
- Não requer IExpress

### 7. Interface para Usuário Final

#### Launcher em Batch (LICENCIAR-WIZARD.bat):
```batch
@echo off
:: Verificar privilégios de administrador
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERRO: Necessita privilegios de Administrador
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 1
)

:: Executar o PowerShell com bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0License-Wizard.ps1"
```

### 8. Ferramentas de Gestão

#### Visualizador de Licenças (View-Licenses.ps1):
- Interface gráfica com DataGridView
- Exibir todas as licenças ativas
- Colunas: Cliente, NIF, Instalação, Expiração, Status, Dias Restantes
- Filtros por status
- Exportação para CSV

#### Verificador de Tarefas (Check-ScheduledTasks.ps1):
- Listar todas as tarefas relacionadas ao PRIMAVERA
- Status de cada tarefa (Ready, Running, Disabled)
- Próxima execução agendada
- Opção para remover tarefas individuais

#### Desinstalador Completo (Uninstall-LicenseSystem.ps1):
- Remove todas as tarefas agendadas
- Limpa base de dados
- Remove diretório C:\PrimaveraLicenseVault
- Backup antes da remoção
- Modo interativo com confirmações

### 9. Sistema de Logs

**Estrutura de Logs:**
```
C:\PrimaveraLicenseVault\Logs\
├── Install-{LicenseId}-{DateTime}.log
├── Delete-{LicenseId}-{DateTime}.log
├── Retry-{LicenseId}-{DateTime}.log
└── AnnualCleanup-{Year}.log
```

**Informações a Registrar:**
- Data/hora de cada operação
- Usuário que executou
- Arquivos processados e seus paths
- Hashes calculados
- Erros e exceções
- Resultados de validações

### 10. Segurança e Validações

**Validações Obrigatórias:**
- Verificar privilégios de administrador antes de qualquer operação
- Validar NIF antes de processar
- Verificar integridade dos arquivos (SHA256)
- Confirmar existência de diretórios antes de copiar
- Validar datas (expiração deve ser futura)

**Proteções:**
- Arquivos de licença: Hidden + ReadOnly
- Base de dados: Somente administradores
- Logs: Registro imutável de operações
- Retry state: Proteção contra loops infinitos

### 11. Mensagens e Feedback

**Mensagens de Sucesso:**
```
✓ Licença instalada com sucesso!
✓ Cliente: {Nome}
✓ Período: {Dias} dias
✓ Expira em: {Data} às {Hora}
✓ A licença será removida automaticamente na data de expiração
```

**Mensagens de Erro (com soluções):**
```
✗ ERRO: Instalação do PRIMAVERA não encontrada
  Solução: Instale o PRIMAVERA antes de licenciar

✗ ERRO: Privilégios de Administrador necessários
  Solução: Clique direito no arquivo e selecione "Executar como Administrador"

✗ ERRO: NIF inválido
  Solução: Verifique se o NIF tem 9 dígitos e está correto

✗ ERRO: Arquivos de licença não encontrados
  Solução: Certifique-se que Primavera.hlf e PRILIC.lic estão na mesma pasta
```

### 12. Casos de Uso Principais

#### Caso 1: Técnico Licencia Cliente Novo
1. Técnico executa SETUP-PRIMAVERA-WIZARD.exe
2. Escolhe período de 30 dias
3. Preenche dados do cliente
4. Confirma instalação
5. Sistema instala licença e agenda expiração para 30 dias
6. Cliente usa PRIMAVERA normalmente
7. Após 30 dias: licença removida automaticamente

#### Caso 2: Renovação de Licença Expirada
1. Licença expira após período inicial
2. Sistema tenta remover (retry a cada 2h por 7 dias)
3. Técnico executa novo setup para renovar
4. Nova licença instalada com novo período
5. Ambos os registros mantidos na base de dados

#### Caso 3: Limpeza Anual
1. 31 de Dezembro às 23:59
2. Tarefa anual executa automaticamente
3. Remove todas as licenças do sistema
4. Limpa base de dados
5. Mantém logs para auditoria

### 13. Requisitos Técnicos

**PowerShell:**
- Versão: 5.1 ou superior
- Execution Policy: Bypass para execução
- Módulos: System.Windows.Forms, System.Drawing

**Windows:**
- Sistema: Windows 7 ou superior
- Permissões: Administrador obrigatório
- Task Scheduler: Habilitado
- IExpress: Nativo do Windows (C:\Windows\System32\iexpress.exe)

**Arquivos Base Necessários:**
- Primavera.hlf (licença fornecida)
- PRILIC.lic (configuração fornecida)

### 14. Estrutura de Arquivos do Projeto

```
Scripts/
├── Interfaces de Licenciamento/
│   ├── License-Wizard.ps1 (Interface wizard - 5 etapas)
│   ├── License-Primavera.ps1 (Interface formulário simples)
│   ├── LICENCIAR-WIZARD.bat (Launcher wizard)
│   └── LICENCIAR.bat (Launcher simples)
│
├── Scripts de Expiração/
│   ├── Delete-IndividualLicense.ps1 (Expiração individual + retry)
│   └── Delete-PrimaveraFiles.ps1 (Limpeza anual completa)
│
├── Geradores de Setup/
│   ├── Create-ExecutableSetup.ps1 (Gera .exe com IExpress)
│   ├── Create-WizardSetup.ps1 (Gera .ps1 wizard auto-extraível)
│   ├── Create-LicenseSetup.ps1 (Gera .ps1 simples auto-extraível)
│   ├── CRIAR-EXE-WIZARD.bat (Interface para gerar .exe wizard)
│   └── CRIAR-EXE-SIMPLES.bat (Interface para gerar .exe simples)
│
├── Ferramentas de Gestão/
│   ├── View-Licenses.ps1 (Visualizador gráfico de licenças)
│   ├── Check-ScheduledTasks.ps1 (Verificador de tarefas)
│   └── Uninstall-LicenseSystem.ps1 (Desinstalador completo)
│
├── Arquivos de Licença/
│   ├── Primavera.hlf (Licença base)
│   └── PRILIC.lic (Configuração)
│
└── Documentação/
    ├── README.md (Visão geral)
    ├── README-Licensing.md (Sistema de licenciamento)
    ├── DOCUMENTACAO-AUTONOMIA-LICENCAS.md (Autonomia técnica)
    └── FUNCIONALIDADES-IMPLEMENTADAS.md (Features completas)
```

### 15. Estatísticas do Sistema

**Complexidade:**
- 29 arquivos no total
- ~3.500 linhas de código PowerShell
- 8 componentes principais

**Capacidades:**
- 2 interfaces de licenciamento
- 2 métodos de expiração (individual + anual)
- 3 formatos de distribuição (.exe, .ps1 wizard, .ps1 simples)
- 3 ferramentas de gestão

**Automação:**
- 100% automático após instalação
- Retry inteligente por 7 dias
- Limpeza anual sem intervenção

### 16. Melhores Práticas de Implementação

1. **Sempre validar entrada do usuário** antes de processar
2. **Criar backups** antes de modificar arquivos existentes
3. **Registrar todas as operações** em logs detalhados
4. **Usar try-catch-finally** para tratamento de erros robusto
5. **Verificar privilégios** no início de cada script
6. **Calcular hashes** para verificação de integridade
7. **Usar GUIDs únicos** para identificação de licenças
8. **Implementar retry logic** para operações que podem falhar
9. **Manter base de dados sincronizada** com o estado real
10. **Fornecer feedback claro** ao usuário em cada etapa

### 17. Fluxo de Dados Completo

```
[Técnico]
    ↓ Executa Setup
[SETUP-PRIMAVERA-WIZARD.exe]
    ↓ Extrai arquivos
[setup_launcher.bat]
    ↓ Verifica admin
[LICENCIAR-WIZARD.bat]
    ↓ Lança PowerShell
[License-Wizard.ps1]
    ↓ Coleta dados
    ↓ Valida NIF
    ↓ Busca instalação PRIMAVERA
    ↓ Copia licenças + aplica atributos
    ↓ Calcula hashes
    ↓ Salva em JSON
    ↓ Agenda tarefa individual
[Task Scheduler]
    ↓ Na data de expiração
[Delete-IndividualLicense.ps1]
    ↓ Remove licenças específicas
    ↓ Se falhar: retry 2h por 7 dias
    ↓ Atualiza status no JSON
[Database]
    ↓ Registro persistente para auditoria
```

### 18. Tratamento de Cenários Especiais

#### Licença não pode ser removida (arquivo em uso):
- Retry automático a cada 2 horas
- Continua tentando por 7 dias
- Após 7 dias: marca como "Expired-Failed" mas mantém registro

#### Múltiplas instalações do PRIMAVERA:
- Busca em todos os diretórios comuns
- Instala licença em todas as localizações encontradas
- Registra todos os paths no JSON

#### Cliente sem dados de NIF:
- Permite NIF opcional (validação pulada se vazio)
- Mantém outros dados para referência

#### Renovação antes da expiração:
- Permite múltiplas licenças ativas
- Cada uma com seu próprio agendamento
- Todas registradas separadamente no JSON

## Resultado Final Esperado

Ao implementar este sistema completo, você deve entregar:

1. **Um executável profissional (.exe)** que pode ser distribuído para técnicos
2. **Interface wizard intuitiva** com 5 etapas claras
3. **Expiração 100% automática** sem necessidade de intervenção manual
4. **Base de dados completa** de todas as licenças para auditoria
5. **Sistema de retry inteligente** que garante remoção mesmo com falhas temporárias
6. **Ferramentas de gestão** para visualizar e gerenciar licenças
7. **Logs detalhados** de todas as operações
8. **Documentação completa** para manutenção futura

## Validação da Implementação

Para validar se a implementação está correta:

✓ O executável deve funcionar em qualquer Windows com um duplo clique
✓ A interface deve ser visualmente profissional e intuitiva
✓ O NIF deve ser validado corretamente usando o algoritmo módulo 11
✓ As licenças devem ser instaladas em todas as localizações do PRIMAVERA
✓ As tarefas agendadas devem ser criadas corretamente no Task Scheduler
✓ A base de dados JSON deve ser atualizada em todas as operações
✓ Os logs devem registrar todas as operações com detalhes
✓ As licenças devem ser removidas automaticamente na data de expiração
✓ O sistema de retry deve funcionar para licenças que não podem ser removidas
✓ A limpeza anual deve remover todas as licenças no final do ano

---

**Tecnologias:** PowerShell 5.1+, Windows Forms, IExpress, Task Scheduler, JSON
**Público-alvo:** Técnicos de TI para licenciamento temporário do PRIMAVERA ERP
**Complexidade:** Intermediária-Avançada (~3.500 linhas de código)
**Plataforma:** Windows 7+ com privilégios de Administrador
