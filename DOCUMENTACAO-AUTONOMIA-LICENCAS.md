# Licenciamento Autônomo com Arquivos Embutidos

Este documento explica como o sistema garante a ativação de licenças de forma autônoma em qualquer máquina, usando os arquivos de licença que já acompanham este repositório.

## Visão Geral

- Os arquivos **Primavera.hlf** e **PRILIC.lic** estão incluídos no pacote na mesma pasta dos scripts.
- Durante o setup e o licenciamento, os arquivos são lidos diretamente do pacote (sem cópia para `C:\\PrimaveraLicenseVault`).
- Se algum arquivo estiver ausente no pacote, o script interrompe e alerta quais itens precisam ser adicionados manualmente.
- Os arquivos embutidos são marcados como **ocultos e somente leitura** automaticamente para reduzir acesso indevido.
- Todo o conteúdo do pacote (scripts, utilitários e documentação) é encapsulado como **oculto + somente leitura**, mantendo visível apenas o `LICENCIAR.bat` para facilitar a execução pelo operador.

## Fluxo Automático

1. **Setup inicial** (`Setup-LicensingSystem.ps1`):
   - Cria apenas a estrutura de suporte (`Database`, `Backups` e `Logs`) em `C:\\PrimaveraLicenseVault`.
   - Informa que os arquivos de licença serão usados diretamente do pacote.
   - Interrompe somente se um arquivo essencial estiver ausente no pacote.

2. **Licenciamento** (`License-Primavera.ps1`):
   - Valida a presença dos arquivos embutidos diretamente na pasta do pacote antes de seguir.
   - Ajusta os atributos de `Primavera.hlf` e `PRILIC.lic` para **oculto + somente leitura** antes de copiar para o PRIMAVERA.
   - Encapsula automaticamente todos os demais arquivos do pacote, preservando acesso direto apenas ao `LICENCIAR.bat`.
   - Cria automaticamente a pasta `Logs` e o arquivo `licensing.log` no `PrimaveraLicenseVault` antes de registrar qualquer mensagem.
   - Continua com o processo normal de cópia para as pastas do PRIMAVERA e agenda tarefas de expiração.

## Benefícios

- **Autonomia total:** nenhuma dependência de arquivos externos ou da máquina do usuário.
- **Previsibilidade:** os arquivos de licença corretos são sempre utilizados a partir do pacote.
- **Segurança:** se um arquivo estiver ausente, o sistema sinaliza claramente para que seja reposto.

## Como Validar

1. Execute `Setup-LicensingSystem.ps1` como administrador e verifique a mensagem avisando que os arquivos serão usados diretamente do pacote.
2. Confirme que os arquivos `Primavera.hlf` e `PRILIC.lic` estão na mesma pasta dos scripts do repositório.
3. Rode `LICENCIAR.bat` e prossiga normalmente; o script verificará os arquivos embutidos antes de iniciar o licenciamento.

Com esse fluxo, o licenciamento pode ser realizado em qualquer máquina compatível sem passos manuais adicionais.

## Solução de Problemas Rápida

- Se o `License-Primavera.ps1` exibir erro de sintaxe logo ao iniciar, verifique se a linha de separador do log está completa:
  `Write-LicenseLog "========================================="`. Restaure a linha exatamente como acima para evitar falhas de
  parsing que impedem o carregamento do formulário de licenciamento.
- Se surgir um aviso de **arquivo master ausente** (ex.: `Primavera.hlf` ou `PRILIC.lic`), confirme que ambos estão na mesma
  pasta que o `LICENCIAR.bat`. Sem esses arquivos o licenciamento é interrompido de propósito para evitar uma ativação
  incompleta. Reponha os arquivos a partir do repositório e execute novamente.
- Caso o script não consiga ler ou proteger os arquivos master (por exemplo, bloqueio de antivírus), ele registra o erro,
  mostra o alerta e encerra a inicialização sem continuar o licenciamento. Remova o bloqueio, confirme a presença dos
  masters e execute o `LICENCIAR.bat` novamente.
