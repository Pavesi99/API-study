$ErrorActionPreference = 'Stop'
$assemblyPath = Join-Path $PSScriptRoot 'ProductKnowledgeLab/bin/Debug/net10.0/ProductKnowledgeLab.dll'
if (-not (Test-Path -LiteralPath $assemblyPath)) {
    throw 'Build the project in Debug configuration before running offline checks.'
}

$checks = @(
    @{ Name = 'Missing both variables'; Key = $null; Model = $null; Arguments = ''; Expected = 'Configuration missing' },
    @{ Name = 'Missing key'; Key = $null; Model = 'offline-placeholder'; Arguments = ''; Expected = 'Configuration missing' },
    @{ Name = 'Missing model'; Key = 'offline-placeholder'; Model = $null; Arguments = ''; Expected = 'Configuration missing' },
    @{ Name = 'Empty question'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = ''; Expected = 'A non-empty question is required' },
    @{ Name = 'Unknown argument'; Key = $null; Model = $null; Arguments = '--unknown'; Expected = 'Usage:' },
    @{ Name = 'Missing configuration without docs'; Key = $null; Model = $null; Arguments = '--without-docs'; Expected = 'Configuration missing' },
    @{ Name = 'Portuguese language'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language Portuguese'; Expected = 'A non-empty question is required' },
    @{ Name = 'English language'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language English'; Expected = 'A non-empty question is required' },
    @{ Name = 'Other language'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language Japanese'; Expected = 'A non-empty question is required' },
    @{ Name = 'Language code'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language fr-FR'; Expected = 'A non-empty question is required' },
    @{ Name = 'Language with spaces'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language "Brazilian Portuguese"'; Expected = 'A non-empty question is required' },
    @{ Name = 'Language before without docs'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--language en --without-docs'; Expected = 'A non-empty question is required' },
    @{ Name = 'Language after without docs'; Key = 'offline-placeholder'; Model = 'offline-placeholder'; Arguments = '--without-docs --language pt-BR'; Expected = 'A non-empty question is required' },
    @{ Name = 'Missing language'; Key = $null; Model = $null; Arguments = '--language'; Expected = 'Usage:' },
    @{ Name = 'Blank language'; Key = $null; Model = $null; Arguments = '--language " "'; Expected = 'Invalid language:' },
    @{ Name = 'Option as language'; Key = $null; Model = $null; Arguments = '--language --without-docs'; Expected = 'Invalid language:' },
    @{ Name = 'Duplicate language'; Key = $null; Model = $null; Arguments = '--language en --language pt'; Expected = 'Usage:' },
    @{ Name = 'Invalid language characters'; Key = $null; Model = $null; Arguments = '--language en!'; Expected = 'Invalid language:' },
    @{ Name = 'Language too long'; Key = $null; Model = $null; Arguments = ('--language ' + ('a' * 81)); Expected = 'Invalid language:' }
)

foreach ($check in $checks) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'dotnet'
    $startInfo.Arguments = '"' + $assemblyPath + '" ' + $check.Arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    # Remove inherited credentials without reading their values.
    $startInfo.EnvironmentVariables.Remove('OPENAI_API_KEY')
    $startInfo.EnvironmentVariables.Remove('OPENAI_MODEL')
    if ($check.Key) { $startInfo.EnvironmentVariables['OPENAI_API_KEY'] = $check.Key }
    if ($check.Model) { $startInfo.EnvironmentVariables['OPENAI_MODEL'] = $check.Model }
    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        $process.StandardInput.Close()
        $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 1 -or -not $output.Contains($check.Expected)) {
            throw "Offline check failed: $($check.Name)"
        }
        Write-Output "PASS: $($check.Name)"
    }
    finally { $process.Dispose() }
}
