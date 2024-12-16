$URL = "https://cert.pl/uploads/2022/01/hasla/resources/wordlist_pl.zip"
$FILENAME = [System.IO.Path]::GetFileName($URL)
$OUTPUT_JSON_FILE_NAME = "common_passwords"
$OUTPUT_DIR = "./passwords"
$MAX_ENTRIES_PER_SET = 100
$MAX_SETS_PER_FILE = 1000


function Invoke-Main {
    Invoke-ArchiveDownload
    Invoke-ArchiveExtraction
    Invoke-ConversionToJSON
    Remove-Item -Path "./$FILENAME"
    Remove-Item -Path "./$TXT_FILE_NAME"
}

function Invoke-ArchiveDownload {
    Write-Host "Downloading $FILENAME..."
    Invoke-WebRequest -Uri $URL -OutFile $FILENAME -UseBasicParsing

    if (-Not (Test-Path -Path $FILENAME)) {
        Write-Host "Error: Failed to download $FILENAME from $URL."
        exit 1
    }
    Write-Host "Download complete."
}

function Invoke-ArchiveExtraction {
    Write-Host "Extracting ZIP file..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($FILENAME, "./")
    $global:TXT_FILE_NAME = (Get-ChildItem -Path "./" -Filter "*.txt").Name

    if (-Not (Test-Path -Path $TXT_FILE_NAME)) {
        Write-Host "Error: Failed to extract $FILENAME."
        exit 1
    }
    Write-Host "Extraction complete."
}

function Invoke-ConversionToJSON {
    Write-Host "Converting to JSON..."
    $inputPath = "./$($Global:TXT_FILE_NAME)"
    $outputPath = "$OUTPUT_DIR/$OUTPUT_JSON_FILE_NAME"

    if (-Not (Test-Path -Path $OUTPUT_DIR)) {
        $null = New-Item -Path $OUTPUT_DIR -ItemType Directory
    }

    $passwords = Get-Content -Path $inputPath
    $FileNumber = 0
    $SetNumber = 0
    $index = 0
    while ($index -lt $passwords.Count) {
        $JSON_STRUCT = New-Object System.Collections.ArrayList

        for ($i = 0; $i -lt $MAX_SETS_PER_FILE; $i++) {
            $result = Get-PasswordsSet -WordsList $passwords -index $index
            $index = $result.index
            $PasswordsList = $result.passwords
            $null = $JSON_STRUCT.Add(@{"cert_pl" = $PasswordsList})
            $SetNumber++
        }
        $JSON_STRUCT | ConvertTo-Json -Depth 3 | Out-File -FilePath "$($outputPath)_$FileNumber.json" -Encoding utf8
        $FileNumber++
    }
    Write-Host "Conversion to JSON complete."
}

function Get-PasswordsSet {
    param(
        $WordsList,
        $index
    )
    $list = New-Object System.Collections.ArrayList
    for ($i = $index; ($i - $index) -lt $MAX_ENTRIES_PER_SET; $i++) {
        $pass = $WordsList[$i]
        try {
            $null = $list.Add($pass.Trim())
        }
        catch {}
    }
    return @{
        "index" = $i
        "passwords" = $list
    }
}

Invoke-Main