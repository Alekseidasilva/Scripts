# Wizard de Licenciamento PRIMAVERA 🧙‍♂️

## Visão Geral

Interface gráfica profissional em formato wizard (assistente) para licenciamento do sistema PRIMAVERA. Guia o usuário através de múltiplas etapas com navegação intuitiva.

## ✨ Características

### Interface Wizard Profissional
- **5 Etapas** com navegação Avançar/Voltar
- **Design Moderno** com cores e tipografia profissional
- **Validação em Tempo Real** de NIF e email
- **Barra de Progresso** durante instalação
- **Resumo de Confirmação** antes de instalar
- **Feedback Visual** em cada etapa

### Etapas do Wizard

#### 1️⃣ Boas-Vindas
- Apresentação do sistema
- Explicação do processo
- Lista de tarefas que serão executadas

#### 2️⃣ Seleção de Período
- Escolha visual entre 4 opções:
  - 3 meses (90 dias)
  - 6 meses (180 dias)
  - 1 ano (365 dias)
  - 2 anos (730 dias)
- Descrição detalhada de cada opção
- Seleção com painéis visuais

#### 3️⃣ Informações do Cliente
- Nome da Empresa (obrigatório)
- NIF com validação portuguesa (9 dígitos)
- Email com validação de formato
- Morada (campo multi-linha)
- Validação antes de prosseguir

#### 4️⃣ Confirmação
- Resumo completo de todos os dados
- Informações do cliente
- Período selecionado
- Datas de início e expiração
- Botão "Instalar" para confirmar

#### 5️⃣ Instalação/Progresso
- Barra de progresso animada
- Status detalhado de cada passo:
  - Inicializando sistema
  - Gerando ID de licença
  - Copiando arquivos
  - Agendando exclusão
  - Salvando informações
- Log detalhado de operações
- Mensagem de sucesso final

## 🚀 Como Usar

### Para Criar o Setup Wizard

#### Opção 1: Usando BAT (Recomendado)

```batch
# Executar como Administrador
CRIAR-SETUP-WIZARD.bat
```

#### Opção 2: Usando PowerShell

```powershell
# Setup genérico
.\Create-WizardSetup.ps1

# Setup personalizado
.\Create-WizardSetup.ps1 -ClientName "Nome do Cliente" -OutputPath "C:\Setups\ClienteX-Wizard.ps1"
```

### Para Testar Localmente

```batch
# Executar como Administrador
LICENCIAR-WIZARD.bat
```

### Para Usar o Setup

1. **Executar o arquivo** `SETUP-WIZARD-PRIMAVERA.ps1` como Administrador
2. **Auto-extração** dos arquivos em pasta temporária
3. **Wizard abre automaticamente**
4. **Seguir as 5 etapas**:
   - Ler boas-vindas → Clicar "Avançar"
   - Escolher período → Clicar "Avançar"
   - Preencher dados do cliente → Clicar "Avançar"
   - Confirmar informações → Clicar "Instalar"
   - Aguardar instalação → Clicar "Finalizar"

## 🎨 Interface Visual

### Cores do Tema

- **Azul Primário**: `#007ACC` - Header e botões principais
- **Cinza Claro**: `#F0F0F0` - Footer e painéis
- **Verde Sucesso**: `#4CAF50` - Mensagens de sucesso
- **Laranja Aviso**: `#FF9800` - Avisos
- **Vermelho Erro**: `#F44336` - Mensagens de erro

### Fontes

- **Títulos**: Segoe UI Bold, 14pt
- **Subtítulos**: Segoe UI Bold, 11pt
- **Texto Normal**: Segoe UI, 10pt
- **Logs**: Consolas, 8-9pt

### Layout

```
┌─────────────────────────────────────────────┐
│  Header (Azul)                               │
│  - Título do Wizard                          │
│  - Subtítulo da Etapa Atual                  │
├─────────────────────────────────────────────┤
│                                               │
│  Área de Conteúdo (Branco)                   │
│  - Conteúdo da etapa atual                   │
│  - Formulários/Seleções                      │
│  - Resumos/Logs                              │
│                                               │
├─────────────────────────────────────────────┤
│  Footer (Cinza)                              │
│  [Passo X de 5]  [<Voltar] [Avançar>] [Cancelar] │
└─────────────────────────────────────────────┘
```

## 📋 Comparação: Wizard vs. Formulário Simples

| Característica | Wizard | Formulário Simples |
|----------------|--------|-------------------|
| Etapas | 5 separadas | 1 única tela |
| Navegação | Avançar/Voltar | Apenas Confirmar |
| UX | Guiado passo a passo | Tudo de uma vez |
| Validação | Por etapa | No final |
| Progresso | Visível e animado | Não visível |
| Feedback | Detalhado em tempo real | Mensagem final |
| Adequado para | Usuários iniciantes | Usuários experientes |
| Tempo de uso | ~2-3 minutos | ~1 minuto |
| Profissionalismo | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

## 🔧 Arquivos do Sistema Wizard

| Arquivo | Descrição | Tamanho Aprox. |
|---------|-----------|----------------|
| `CRIAR-SETUP-WIZARD.bat` | Criador do setup (BAT) | ~2 KB |
| `Create-WizardSetup.ps1` | Gerador do setup (PS1) | ~9 KB |
| `LICENCIAR-WIZARD.bat` | Iniciador do wizard (BAT) | ~2 KB |
| `License-Wizard.ps1` | Script principal do wizard | ~35 KB |
| `Delete-IndividualLicense.ps1` | Script de exclusão | ~13 KB |
| `Primavera.hlf` | Arquivo de licença | Variável |
| `PRILIC.lic` | Arquivo de licença | Variável |
| **SETUP-WIZARD-PRIMAVERA.ps1** | **Setup final gerado** | **~50-70 KB** |

## 💡 Vantagens do Wizard

### Para o Técnico/Administrador

✅ **Profissionalismo** - Interface moderna e polida
✅ **Facilidade** - Simples de distribuir (1 arquivo)
✅ **Confiança** - Cliente vê interface profissional
✅ **Suporte Reduzido** - Interface auto-explicativa

### Para o Cliente/Usuário Final

✅ **Clareza** - Cada passo bem explicado
✅ **Segurança** - Confirmação antes de instalar
✅ **Feedback** - Sabe exatamente o que está acontecendo
✅ **Reversão** - Pode voltar para corrigir dados

### Para o Sistema

✅ **Validação** - Dados validados antes de prosseguir
✅ **Logs** - Registro detalhado de cada operação
✅ **Robustez** - Tratamento de erros em cada etapa
✅ **Rastreabilidade** - Histórico completo no banco de dados

## 🎯 Casos de Uso

### Uso Recomendado

- ✅ Licenciamento em campo (técnicos)
- ✅ Instalações em clientes
- ✅ Demonstrações comerciais
- ✅ Treinamento de novos técnicos
- ✅ Auto-serviço por clientes

### Quando Usar Formulário Simples

- ⚠️ Licenciamento interno rápido
- ⚠️ Usuários muito experientes
- ⚠️ Automação via scripts
- ⚠️ Processos batch

## 🔒 Segurança

Todas as medidas de segurança do sistema padrão são mantidas:

- ✅ Requer privilégios de Administrador
- ✅ Arquivos master protegidos (hidden + readonly)
- ✅ Validação de NIF português
- ✅ Validação de email
- ✅ Logs de auditoria completos
- ✅ Backup automático antes de copiar
- ✅ Verificação de integridade (SHA256)

## 📊 Fluxo de Dados

```
Etapa 1 (Boas-Vindas)
    ↓
    [Usuário clica "Avançar"]
    ↓
Etapa 2 (Período)
    ↓
    [Usuário seleciona período]
    [Dados salvos em $wizardData.Period]
    [Usuário clica "Avançar"]
    ↓
Etapa 3 (Cliente)
    ↓
    [Usuário preenche formulário]
    [Validação de NIF e Email]
    [Dados salvos em $wizardData.{CompanyName, NIF, Email, Address}]
    [Usuário clica "Avançar"]
    ↓
Etapa 4 (Confirmação)
    ↓
    [Sistema monta resumo com todos os dados]
    [Calcula datas de início e expiração]
    [Exibe resumo completo]
    [Usuário clica "Instalar"]
    ↓
Etapa 5 (Instalação)
    ↓
    [Gera ID de licença]
    [Copia arquivos]
    [Agenda exclusão]
    [Atualiza banco de dados]
    [Exibe sucesso]
    [Usuário clica "Finalizar"]
    ↓
    [Wizard fecha]
```

## 🐛 Solução de Problemas

### Wizard não abre

**Problema**: Nada acontece ao executar

**Soluções**:
```powershell
# 1. Verificar ExecutionPolicy
Get-ExecutionPolicy

# 2. Executar com bypass
powershell -ExecutionPolicy Bypass -File SETUP-WIZARD-PRIMAVERA.ps1

# 3. Verificar se é Administrador
net session
```

### Erros de validação

**Problema**: NIF não aceito

**Solução**: NIF português deve ter 9 dígitos e passar na validação de checksum

**Problema**: Email não aceito

**Solução**: Formato deve ser `usuario@dominio.extensao`

### Instalação falha

**Problema**: Erro ao copiar arquivos

**Verificar**:
1. PRIMAVERA está instalado?
2. Permissões de Administrador?
3. Ver logs em `C:\PrimaveraLicenseVault\Logs\`

## 📞 Suporte

Para problemas específicos do wizard:

1. Verificar logs em `C:\PrimaveraLicenseVault\Logs\licensing.log`
2. Verificar se todos os arquivos foram extraídos
3. Testar com `LICENCIAR-WIZARD.bat` localmente
4. Verificar mensagens de erro na etapa de instalação

## 🎓 Tutorial Rápido

### Para o Administrador (Criar Setup)

1. Abra `CRIAR-SETUP-WIZARD.bat` como Admin
2. (Opcional) Digite nome do cliente
3. Aguarde criação do setup
4. Envie `SETUP-WIZARD-PRIMAVERA.ps1` ao técnico

### Para o Técnico (Usar Setup)

1. Receba `SETUP-WIZARD-PRIMAVERA.ps1`
2. Execute como Administrador
3. Aguarde extração automática
4. Wizard abre automaticamente
5. Siga os 5 passos na tela
6. Pronto! Licença instalada e agendada

---

**Versão**: 1.0
**Última Atualização**: Dezembro 2024
**Compatibilidade**: Windows 7+, PowerShell 5.1+
