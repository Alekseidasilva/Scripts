<#
.SYNOPSIS
Gera um pacote de licenciamento em arquivo único auto-extraível.

.DESCRIPTION
Compacta todos os arquivos do diretório (exceto este gerador e a saída) em um ZIP,
incorpora-o como base64 dentro de um script PowerShell auto-extraível e produz
um arquivo único que, ao ser executado, extrai o conteúdo para uma pasta temporária
(e opcionalmente fixa) e chama o LICENCIAR.bat.

.PARAMETER Output
Caminho do arquivo único a ser gerado. Padrão: ./LICENCIAR-UNICO.ps1

.PARAMETER KeepExtracted
Se definido, mantém a pasta temporária após a execução do arquivo único.

.EXAMPLE
PS C:\Scripts> ./Package-SingleFile.ps1
Gera LICENCIAR-UNICO.ps1 no diretório atual.

.EXAMPLE
PS C:\Scripts> ./Package-SingleFile.ps1 -Output C:\Pacotes\ClienteX.ps1
Gera o pacote único em C:\Pacotes\ClienteX.ps1.
#>
param(
    [string]$Output = "./LICENCIAR-UNICO.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FilesToPackage {
    param(
        [string]$Root
    )
    $excludedNames = @(
        'Package-SingleFile.ps1',
        [IO.Path]::GetFileName($Output)
    )

    Get-ChildItem -LiteralPath $Root -File -Recurse |
        Where-Object {
            $_.FullName -notmatch '\\.git' -and
            -not ($excludedNames -contains $_.Name)
        }
}

function New-TempZip {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Root
    )
    $zipPath = [IO.Path]::GetTempFileName()
    Remove-Item $zipPath -Force
    $zipPath = "$zipPath.zip"

    $filePaths = $Files | ForEach-Object { $_.FullName }
    Compress-Archive -Path $filePaths -DestinationPath $zipPath -Force
    Write-Host "Zip temporário criado em $zipPath"
    return $zipPath
}

function New-SelfExtractingScript {
    param(
        [string]$ZipPath,
        [string]$TargetPath
    )
    $zipBytes = [IO.File]::ReadAllBytes($ZipPath)
    $zipBase64 = [Convert]::ToBase64String($zipBytes)

    $script = @"
<#
Script auto-extraível gerado por Package-SingleFile.ps1
Ao executar, extrai o pacote para uma pasta temporária e chama LICENCIAR.bat.
#>
param(
    [switch]$KeepExtracted
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$extractRoot = Join-Path $env:TEMP "PrimaveraLicenseBundle-$stamp"
$zipPath = Join-Path $extractRoot 'bundle.zip'

Write-Host "Criando pasta temporária em $extractRoot" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

Write-Host "Materializando pacote compactado" -ForegroundColor Cyan
[IO.File]::WriteAllBytes($zipPath, [Convert]::FromBase64String('$zipBase64'))

Write-Host "Extraindo pacote" -ForegroundColor Cyan
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force

$licenciar = Join-Path $extractRoot 'LICENCIAR.bat'
if (-not (Test-Path $licenciar)) {
    throw "LICENCIAR.bat não encontrado após extração."
}

Write-Host "Executando LICENCIAR.bat" -ForegroundColor Green
$process = Start-Process -FilePath $licenciar -WorkingDirectory $extractRoot -PassThru -Wait

if (-not $KeepExtracted) {
    Write-Host "Limpando pasta temporária" -ForegroundColor Yellow
    Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Pasta temporária preservada em $extractRoot" -ForegroundColor Yellow
}

exit $process.ExitCode
"@

    Set-Content -LiteralPath $TargetPath -Value $script -Encoding UTF8
    Write-Host "Arquivo único criado em $TargetPath" -ForegroundColor Green
}

$root = Get-Location
$files = Get-FilesToPackage -Root $root
if (-not $files) {
    throw "Nenhum arquivo encontrado para empacotar."
}

$zipPath = New-TempZip -Files $files -Root $root
$targetPath = [IO.Path]::GetFullPath($Output)
try {
    New-SelfExtractingScript -ZipPath $zipPath -TargetPath $targetPath
}
finally {
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
}
