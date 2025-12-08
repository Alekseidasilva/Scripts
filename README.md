# Scripts PRIMAVERA

Coleção de scripts para gerenciamento e licenciamento do sistema PRIMAVERA.

## 📋 Sistemas Disponíveis

### 🔐 Sistema de Licenciamento Autocontido

Sistema completo de licenciamento com setup autoextraível e agendamento automático de exclusão.

**Duas Interfaces Disponíveis**:

#### 🧙‍♂️ Wizard (Recomendado)
Interface profissional com múltiplas etapas guiadas

**Características**:
- **5 etapas** com navegação Avançar/Voltar
- Interface moderna e intuitiva
- Validação em tempo real
- Barra de progresso durante instalação
- **Agendamento automático de exclusão**

**Como usar**:
1. Execute `CRIAR-SETUP-WIZARD.bat` como Administrador
2. Distribua o arquivo `SETUP-WIZARD-PRIMAVERA.ps1` gerado
3. O técnico/cliente segue as etapas do wizard
4. A licença será removida automaticamente ao expirar

**Documentação**: [README-Wizard.md](README-Wizard.md)

#### 📝 Formulário Simples
Interface rápida em uma única tela

**Características**:
- Formulário único consolidado
- Validação de NIF e email
- Escolha de período (3m, 6m, 1a, 2a)
- **Agendamento automático de exclusão**

**Como usar**:
1. Execute `CRIAR-SETUP.bat` como Administrador
2. Distribua o arquivo `SETUP-LICENCIAMENTO-PRIMAVERA.ps1` gerado
3. O técnico/cliente preenche e confirma
4. A licença será removida automaticamente ao expirar

**Documentação**: [README-Setup-Licenciamento.md](README-Setup-Licenciamento.md)

### 🗑️ Sistema de Limpeza Anual PRIMAVERA

Sistema de limpeza automática de arquivos PRIMAVERA (anual).

**Documentação**: [README-PrimaveraCleanup.md](README-PrimaveraCleanup.md)

### 📝 Sistema de Renovação de Licenças

Ferramentas para renovação de licenças existentes.

**Documentação**: [README-Licensing.md](README-Licensing.md)

## 🚀 Início Rápido

### Para Criar um Setup de Licenciamento

```batch
# EXECUTÁVEL .EXE (Mais Profissional - Recomendado para técnicos)
CRIAR-EXE-WIZARD.bat        # Wizard com 5 etapas
CRIAR-EXE-SIMPLES.bat       # Formulário simples

# SCRIPT .PS1 (Para uso interno/desenvolvimento)
CRIAR-SETUP-WIZARD.bat      # Wizard com 5 etapas
CRIAR-SETUP.bat             # Formulário simples
```

### Para Licenciar Manualmente (sem setup)

```batch
# Execute como Administrador
LICENCIAR.bat
```

### Para Consultar Licenças

```batch
CONSULTAR-LICENCAS.bat
```

## 📚 Documentação Detalhada

- **[Executáveis (.exe)](README-Executavel.md)** - Criar executáveis profissionais (RECOMENDADO PARA DISTRIBUIÇÃO)
- **[Wizard de Licenciamento](README-Wizard.md)** - Interface wizard profissional
- **[Setup de Licenciamento](README-Setup-Licenciamento.md)** - Interface formulário simples
- **[Licenciamento](README-Licensing.md)** - Sistema de licenciamento e renovação
- **[Limpeza PRIMAVERA](README-PrimaveraCleanup.md)** - Sistema de limpeza anual
- **[Autonomia de Licenças](DOCUMENTACAO-AUTONOMIA-LICENCAS.md)** - Documentação técnica
- **[Pacote Único](PACOTE-UNICO.md)** - Como criar pacotes únicos

## 🛠️ Arquivos Principais

### Geradores de Executáveis (.exe) - Distribuição
| Arquivo | Descrição |
|---------|-----------|
| `CRIAR-EXE-WIZARD.bat` | 💾⭐⭐⭐ Criar .exe com Wizard (RECOMENDADO) |
| `CRIAR-EXE-SIMPLES.bat` | 💾⭐⭐ Criar .exe com formulário simples |

### Geradores de Scripts (.ps1) - Desenvolvimento
| Arquivo | Descrição |
|---------|-----------|
| `CRIAR-SETUP-WIZARD.bat` | 🧙‍♂️⭐⭐ Criar .ps1 com Wizard |
| `CRIAR-SETUP.bat` | 📝⭐ Criar .ps1 com formulário simples |

### Licenciamento Local
| Arquivo | Descrição |
|---------|-----------|
| `LICENCIAR-WIZARD.bat` | 🧙‍♂️ Licenciar com interface wizard |
| `LICENCIAR.bat` | 📝 Licenciar com formulário simples |

### Gestão de Licenças
| Arquivo | Descrição |
|---------|-----------|
| `CONSULTAR-LICENCAS.bat` | 📊 Consultar licenças ativas |
| `RENOVAR-LICENCA.bat` | 🔄 Renovar licença existente |
| `DESINSTALAR.bat` | 🗑️ Desinstalar sistema de licenciamento |

## ⚙️ Requisitos

- Windows 7 ou superior
- PowerShell 5.1 ou superior
- Permissões de Administrador
- PRIMAVERA instalado (para licenciamento)

## 📦 Estrutura de Diretórios

```
C:\PrimaveraLicenseVault\
├── Database\           # Banco de dados de licenças
│   └── licenses.json
├── Logs\              # Logs do sistema
│   ├── licensing.log
│   └── deletion_log.txt
├── Backups\           # Backups de arquivos
└── DeletionState\     # Estados de retry de exclusão
```

## 🔒 Segurança

- Todos os scripts requerem privilégios de Administrador
- Arquivos master protegidos (hidden + readonly)
- Validação de NIF português
- Logs de auditoria completos
- Sistema de backup automático

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes