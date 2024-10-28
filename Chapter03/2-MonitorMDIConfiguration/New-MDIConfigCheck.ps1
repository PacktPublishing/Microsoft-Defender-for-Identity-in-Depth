function Format-JsonSingleLine {
    param(
        [Parameter(Mandatory, ValueFromPipeline)] 
        [String] $json
    )

    # Remove all newline characters and unnecessary spaces
    $json = $json -replace '\s+', ' ' -replace '\s*([{}\[\]:,])\s*', '$1'
    return $json
}

function Rotate-LogFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        [int]$MaxFileSizeMB = 5
    )

    if (Test-Path $FilePath) {
        $fileSizeMB = (Get-Item $FilePath).Length / 1MB
        if ($fileSizeMB -ge $MaxFileSizeMB) {
            Write-Host "File size is $fileSizeMB MB, exceeding $MaxFileSizeMB MB. Deleting and recreating the file." -ForegroundColor Yellow
            Remove-Item $FilePath -Force
            New-Item -ItemType File -Path $FilePath
        }
    } else {
        Write-Host "File does not exist, creating a new one." -ForegroundColor Green
        New-Item -ItemType File -Path $FilePath
    }
}

function Append-JsonLog {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [object]$Data,
        [int]$MaxFileSizeMB = 5
    )

    try {
        # Rotate log file if it exceeds the specified size
        Rotate-LogFile -FilePath $FilePath -MaxFileSizeMB $MaxFileSizeMB

        # Convert the data to JSON in a single line
        $json = $Data | ConvertTo-Json -Depth 5 | Format-JsonSingleLine

        # Append the JSON data to the file
        Add-Content -Path $FilePath -Value $json
        Write-Host "Appended JSON data to $FilePath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to append JSON data: $_"
    }
}

# Import the necessary module
Import-Module DefenderForIdentity

# Fetch the MDI configuration data
$logData = Get-MDIConfiguration -Configuration All -Mode Domain

# Define the path for the log file
$logFilePath = "C:\Temp\MDIConfig\MDI-configuration.json"

# Append the log data to the file
Append-JsonLog -FilePath $logFilePath -Data $logData
