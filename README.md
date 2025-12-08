# Scripts PRIMAVERA

Coleção de scripts para gerenciamento e licenciamento do sistema PRIMAVERA.

## 📋 Sistemas Disponíveis

### 🔐 Sistema de Licenciamento Autocontido

Sistema completo de licenciamento com setup autoextraível e agendamento automático de exclusão.

**Características**:
- Setup em arquivo único autocontido
- Interface gráfica para licenciamento
- Escolha de período de licença (3m, 6m, 1a, 2a)
- **Agendamento automático de exclusão** baseado no período escolhido
- Sistema de retry inteligente

**Como usar**:
1. Execute `CRIAR-SETUP.bat` como Administrador
2. Distribua o arquivo `SETUP-LICENCIAMENTO-PRIMAVERA.ps1` gerado
3. O técnico/cliente executa o setup e escolhe o período
4. A licença será removida automaticamente ao expirar

**Documentação completa**: [README-Setup-Licenciamento.md](README-Setup-Licenciamento.md)

### 🗑️ Sistema de Limpeza Anual PRIMAVERA

Sistema de limpeza automática de arquivos PRIMAVERA (anual).

**Documentação**: [README-PrimaveraCleanup.md](README-PrimaveraCleanup.md)

### 📝 Sistema de Renovação de Licenças

Ferramentas para renovação de licenças existentes.

**Documentação**: [README-Licensing.md](README-Licensing.md)

## 🚀 Início Rápido

### Para Criar um Setup de Licenciamento

```batch
# Execute como Administrador
CRIAR-SETUP.bat
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

- **[Setup de Licenciamento](README-Setup-Licenciamento.md)** - Sistema completo com agendamento automático
- **[Licenciamento](README-Licensing.md)** - Sistema de licenciamento e renovação
- **[Limpeza PRIMAVERA](README-PrimaveraCleanup.md)** - Sistema de limpeza anual
- **[Autonomia de Licenças](DOCUMENTACAO-AUTONOMIA-LICENCAS.md)** - Documentação técnica
- **[Pacote Único](PACOTE-UNICO.md)** - Como criar pacotes únicos

## 🛠️ Arquivos Principais

| Arquivo | Descrição |
|---------|-----------|
| `CRIAR-SETUP.bat` | ⭐ Criar setup autocontido de licenciamento |
| `LICENCIAR.bat` | Licenciar sistema manualmente |
| `CONSULTAR-LICENCAS.bat` | Consultar licenças ativas |
| `RENOVAR-LICENCA.bat` | Renovar licença existente |
| `DESINSTALAR.bat` | Desinstalar sistema de licenciamento |

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