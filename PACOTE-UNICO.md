# Guia para gerar um único arquivo de licenciamento

Este passo a passo mostra como gerar **um único arquivo PowerShell** que contém todo o pacote de licenciamento. Assim, qualquer técnico pode baixar apenas esse arquivo, executá-lo na máquina do cliente e iniciar o `LICENCIAR.bat` automaticamente sem depender de pastas locais adicionais.

## Pré-requisitos
- Windows com PowerShell 5.1 ou superior.
- Permissão para executar scripts (`Set-ExecutionPolicy RemoteSigned` ou conforme a política da empresa).

## Como gerar o arquivo único
1. Abra um terminal PowerShell na pasta onde estão os scripts de licenciamento.
2. Execute:
   ```powershell
   ./Package-SingleFile.ps1
   ```
   - O script cria o `LICENCIAR-UNICO.ps1` no diretório atual.
   - Ele compacta todos os arquivos do pacote (licenças, scripts, BATs, documentação) e os embute em um único script auto-extraível.

3. Caso queira salvar o pacote em outro lugar ou com outro nome, use:
   ```powershell
   ./Package-SingleFile.ps1 -Output "C:\\Pacotes\\ClienteX.ps1"
   ```

## Como o arquivo único funciona
- Ao ser executado no cliente, ele extrai o conteúdo para uma pasta temporária e chama automaticamente o `LICENCIAR.bat`.
- Por padrão, a pasta temporária é apagada ao final. Se quiser inspecionar o conteúdo extraído, chame o arquivo único com:
  ```powershell
  .\LICENCIAR-UNICO.ps1 -KeepExtracted
  ```
  Isso preserva a pasta temporária para conferência.

## Boas práticas para distribuição
- Gere um pacote novo sempre que atualizar licenças ou scripts.
- Armazene o `LICENCIAR-UNICO.ps1` em um local seguro e verifique a integridade antes de levar ao cliente.
- Documente internamente qual versão do pacote foi entregue a cada cliente.

## Problemas comuns
- **Erro de execução de script bloqueado:** revise a política de execução ou rode o PowerShell como administrador se a política corporativa permitir.
- **Antivírus impedindo extração:** adicione exceção temporária para a pasta `%TEMP%` durante a execução do pacote, conforme as políticas de segurança.
