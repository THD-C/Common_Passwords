$URL = "https://cert.pl/uploads/2022/01/hasla/resources/wordlist_pl.zip"
$FILENAME = [System.IO.Path]::GetFileName($URL)
$OUTPUT_JSON_FILE_NAME = "common_passwords.json"
$OUTPUT_DIR = "./passwords"

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
        New-Item -Path $OUTPUT_DIR -ItemType Directory
    }

    $passwords = Get-Content -Path $inputPath | ForEach-Object { $_.Trim() }
    $json = @{ passwords = $passwords } | ConvertTo-Json -Depth 2

    if (-Not (Test-Path -Path $OUTPUT_DIR)) {
        $null = New-Item -ItemType Directory -Path $OUTPUT_DIR
    }

    $json | Out-File -FilePath $outputPath -Encoding utf8
    Write-Host "Conversion to JSON complete."
}

Invoke-Main