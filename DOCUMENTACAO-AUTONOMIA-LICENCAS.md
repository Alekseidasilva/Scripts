# Licenciamento Autônomo com Arquivos Embutidos

Este documento explica como o sistema garante a ativação de licenças de forma autônoma em qualquer máquina, usando os arquivos de licença que já acompanham este repositório.

## Visão Geral

- Os arquivos **Primavera.hlf** e **PRILIC.lic** estão incluídos no pacote na mesma pasta dos scripts.
- Durante o setup e o licenciamento, os arquivos são copiados automaticamente para `C:\\PrimaveraLicenseVault\\Master`.
- Se algum arquivo estiver ausente no pacote, o script alerta quais itens precisam ser adicionados manualmente.

## Fluxo Automático

1. **Setup inicial** (`Setup-LicensingSystem.ps1`):
   - Cria a estrutura `C:\\PrimaveraLicenseVault`.
   - Copia automaticamente os arquivos de licença do pacote para a pasta `Master`.
   - Exibe alertas somente se algum arquivo não foi encontrado no pacote.

2. **Licenciamento** (`License-Primavera.ps1`):
   - Garante que os arquivos master existam em `Master`; se faltarem, replica os arquivos embutidos antes de prosseguir.
   - Continua com o processo normal de cópia para as pastas do PRIMAVERA e agenda tarefas de expiração.

## Benefícios

- **Autonomia total:** nenhuma dependência de arquivos externos ou da máquina do usuário.
- **Previsibilidade:** os arquivos de licença corretos são sempre utilizados a partir do pacote.
- **Segurança:** se um arquivo estiver ausente, o sistema sinaliza claramente para que seja reposto.

## Como Validar

1. Execute `Setup-LicensingSystem.ps1` como administrador e verifique a mensagem `[COPIADO]` indicando a disponibilidade automática.
2. Após o setup, confirme que `C:\\PrimaveraLicenseVault\\Master` contém `Primavera.hlf` e `PRILIC.lic`.
3. Rode `LICENCIAR.bat` e prossiga normalmente; o script garantirá a presença dos arquivos antes de iniciar o licenciamento.

Com esse fluxo, o licenciamento pode ser realizado em qualquer máquina compatível sem passos manuais adicionais.

## Solução de Problemas Rápida

- Se o `License-Primavera.ps1` exibir erro de sintaxe logo ao iniciar, verifique se a linha de separador do log está completa:
  `Write-LicenseLog "========================================="`. Restaure a linha exatamente como acima para evitar falhas de
  parsing que impedem o carregamento do formulário de licenciamento.
