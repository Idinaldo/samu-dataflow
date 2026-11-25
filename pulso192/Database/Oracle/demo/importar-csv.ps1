param(
    [string]$CsvPath = (Join-Path $PSScriptRoot 'ocorrencias.csv')
)

$ErrorActionPreference = 'Stop'

$csvFile = (Resolve-Path -LiteralPath $CsvPath).Path
$rows = @(Import-Csv -LiteralPath $csvFile -Delimiter ';' -Encoding UTF8)
$templatePath = Join-Path $PSScriptRoot 'ocorrencias.csv.example'
$templateRows = @(Import-Csv -LiteralPath $templatePath -Delimiter ';' -Encoding UTF8)

if ($rows.Count -eq 0) {
    throw 'The CSV file has no data rows.'
}

$headers = @($rows[0].PSObject.Properties | ForEach-Object { $_.Name })
$expectedHeaders = @($templateRows[0].PSObject.Properties | ForEach-Object { $_.Name })
if ($headers.Count -ne $expectedHeaders.Count) {
    throw "Expected $($expectedHeaders.Count) CSV columns, got $($headers.Count)."
}

for ($i = 0; $i -lt $expectedHeaders.Count; $i++) {
    if ($headers[$i] -cne $expectedHeaders[$i]) {
        throw "CSV header or column order differs from the template at column $($i + 1)."
    }
}

$dateIndexes = @(1, 12, 18, 20, 29, 31)
$dateFormats = [string[]]@(
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-MM-ddTHH:mm:ss',
    'dd/MM/yyyy HH:mm:ss',
    'dd/MM/yyyy HH:mm',
    'yyyy-MM-dd'
)
$quotedColumns = @($headers | ForEach-Object { '"' + $_.Replace('"', '""') + '"' })
$seenKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$importedKeys = [System.Collections.Generic.List[string]]::new()
$sql = [System.Text.StringBuilder]::new()

[void]$sql.AppendLine('WHENEVER SQLERROR EXIT SQL.SQLCODE')
[void]$sql.AppendLine('SET FEEDBACK ON')
[void]$sql.AppendLine('SET PAGESIZE 100')
[void]$sql.AppendLine('SET LINESIZE 120')
[void]$sql.AppendLine('COLUMN occurrence FORMAT A20')
[void]$sql.AppendLine('COLUMN data_hora FORMAT A19')
[void]$sql.AppendLine('COLUMN bairro FORMAT A30')
[void]$sql.AppendLine('COLUMN municipio FORMAT A20')
[void]$sql.AppendLine('ALTER SESSION SET CONTAINER=FREEPDB1;')

foreach ($row in $rows) {
    $values = @($row.PSObject.Properties | ForEach-Object { [string]$_.Value })
    if ($values.Count -ne 36) {
        throw "A CSV row has $($values.Count) values instead of 36."
    }

    $key = $values[0].Trim()
    if ([string]::IsNullOrWhiteSpace($key) -or $key.Length -gt 20) {
        throw 'Every row needs an OCORRÊNCIA value of 1 to 20 characters.'
    }
    if ([string]::IsNullOrWhiteSpace($values[1])) {
        throw "Occurrence '$key' has no DATA/HORA CRIAÇÃO."
    }
    if (-not $seenKeys.Add($key)) {
        throw "Occurrence '$key' appears more than once in the CSV."
    }
    $importedKeys.Add($key)
    $values[0] = $key

    $sourceValues = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $values.Count; $i++) {
        $value = $values[$i]

        if ($dateIndexes -contains $i) {
            if ([string]::IsNullOrWhiteSpace($value)) {
                $sqlValue = 'CAST(NULL AS DATE)'
            }
            else {
                $parsedDate = [DateTime]::MinValue
                $parsed = [DateTime]::TryParseExact(
                    $value.Trim(),
                    $dateFormats,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$parsedDate)
                if (-not $parsed) {
                    throw "Occurrence '$key' has an invalid date in column '$($headers[$i])': '$value'."
                }

                $dateText = $parsedDate.ToString(
                    'yyyy-MM-dd HH:mm:ss',
                    [System.Globalization.CultureInfo]::InvariantCulture)
                $sqlValue = "TO_DATE('$dateText', 'YYYY-MM-DD HH24:MI:SS')"
            }
        }
        elseif ([string]::IsNullOrWhiteSpace($value)) {
            $sqlValue = 'NULL'
        }
        else {
            $escapedValue = $value.Replace("'", "''")
            $sqlValue = "'$escapedValue'"
        }

        $sourceValues.Add("$sqlValue AS $($quotedColumns[$i])")
    }

    $updateAssignments = [System.Collections.Generic.List[string]]::new()
    for ($i = 1; $i -lt $quotedColumns.Count; $i++) {
        $updateAssignments.Add("    target.$($quotedColumns[$i]) = source.$($quotedColumns[$i])")
    }

    $insertColumns = $quotedColumns -join ', '
    $insertValues = @($quotedColumns | ForEach-Object { "source.$_" }) -join ', '

    [void]$sql.AppendLine('MERGE INTO SYSTEM.SAMU_OCORRENCIA_BRONZE target')
    [void]$sql.AppendLine('USING (')
    [void]$sql.AppendLine("    SELECT $($sourceValues -join ', ') FROM DUAL")
    [void]$sql.AppendLine(") source ON (target.$($quotedColumns[0]) = source.$($quotedColumns[0]))")
    [void]$sql.AppendLine('WHEN MATCHED THEN UPDATE SET')
    [void]$sql.AppendLine(($updateAssignments -join ",`r`n"))
    [void]$sql.AppendLine("WHEN NOT MATCHED THEN INSERT ($insertColumns)")
    [void]$sql.AppendLine("VALUES ($insertValues);")
}

[void]$sql.AppendLine('COMMIT;')
[void]$sql.AppendLine("SELECT $($quotedColumns[0]) AS occurrence,")
[void]$sql.AppendLine("       TO_CHAR($($quotedColumns[1]), 'YYYY-MM-DD HH24:MI:SS') AS data_hora,")
[void]$sql.AppendLine("       $($quotedColumns[9]) AS bairro,")
[void]$sql.AppendLine("       $($quotedColumns[10]) AS municipio")
[void]$sql.AppendLine('  FROM SYSTEM.SAMU_OCORRENCIA_BRONZE')
$keyList = @($importedKeys | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ', '
[void]$sql.AppendLine(" WHERE $($quotedColumns[0]) IN ($keyList)")
[void]$sql.AppendLine(" ORDER BY $($quotedColumns[1]);")
[void]$sql.AppendLine('EXIT')

$generatedSqlPath = Join-Path $PSScriptRoot '.import-generated.sql'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
[System.IO.File]::WriteAllText(
    $generatedSqlPath,
    $sql.ToString(),
    [System.Text.UTF8Encoding]::new($false))

Push-Location $repositoryRoot
try {
    & docker compose exec -T oracle-db sqlplus -s / as sysdba '@/opt/oracle/scripts/demo/.import-generated.sql'
    $dockerExitCode = $LASTEXITCODE
    if ($dockerExitCode -ne 0) {
        throw "Oracle import failed with exit code $dockerExitCode. Generated SQL was kept at '$generatedSqlPath'."
    }
}
finally {
    Pop-Location
}

Remove-Item -LiteralPath $generatedSqlPath
Write-Output "$($rows.Count) CSV row(s) merged into the Oracle source."
