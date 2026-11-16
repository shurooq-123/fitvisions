param(
    [string]$EncryptedInputBase,
    [string]$Prompt = 'Studio product photograph of an emerald green Omani abaya for Eid, floor length, loose modest silhouette, long sleeves, delicate gold embroidery at cuffs. Full garment on a headless mannequin, plain ivory background, realistic crepe fabric, no text.',
    [string]$InputImage,
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$OutputName = 'abaya'
)
$ErrorActionPreference = 'Stop'
# Enter the key locally. Never save or log the credential.
if ($EncryptedInputBase) {
    # Ephemeral RSA key stays in memory. Only public key and ciphertext touch disk.
    $rsa = [Security.Cryptography.RSA]::Create(3072)
    try {
        [IO.File]::WriteAllText("$EncryptedInputBase.public.pem", $rsa.ExportSubjectPublicKeyInfoPem())
        Write-Host 'Waiting for RSA-OAEP encrypted credential.'
        $deadline = [DateTime]::UtcNow.AddSeconds(120)
        while (-not (Test-Path -LiteralPath "$EncryptedInputBase.ready")) {
            if ([DateTime]::UtcNow -gt $deadline) { throw 'Credential transfer timed out.' }
            Start-Sleep -Milliseconds 200
        }
        $decoded = $rsa.Decrypt([IO.File]::ReadAllBytes("$EncryptedInputBase.bin"), [Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
        $secret = ConvertTo-SecureString ([Text.Encoding]::UTF8.GetString($decoded)) -AsPlainText -Force
        [Array]::Clear($decoded, 0, $decoded.Length)
    } finally {
        $rsa.Dispose()
        foreach ($suffix in @('.public.pem', '.bin', '.ready')) {
            if (Test-Path -LiteralPath "$EncryptedInputBase$suffix") { Remove-Item -LiteralPath "$EncryptedInputBase$suffix" }
        }
    }
} else {
    $secret = Read-Host 'Cloudflare Workers AI token (hidden)' -AsSecureString
}
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
$client = $null
try {
    Add-Type -AssemblyName System.Net.Http
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(180)
    $client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr))
    $form = [System.Net.Http.MultipartFormDataContent]::new()
    $form.Add([System.Net.Http.StringContent]::new($Prompt), 'prompt')
    if ($InputImage) {
        # Model reference images must be smaller than 512x512.
        Add-Type -AssemblyName System.Drawing
        $source = [Drawing.Image]::FromFile((Resolve-Path -LiteralPath $InputImage))
        $scale = [Math]::Min(1.0, 480.0 / [Math]::Max($source.Width, $source.Height))
        $resized = [Drawing.Bitmap]::new($source, [int]($source.Width * $scale), [int]($source.Height * $scale))
        $buffer = [IO.MemoryStream]::new()
        try {
            $resized.Save($buffer, [Drawing.Imaging.ImageFormat]::Jpeg)
            $imagePart = [System.Net.Http.ByteArrayContent]::new($buffer.ToArray())
            $imagePart.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new('image/jpeg')
            $form.Add($imagePart, 'input_image_0', 'reference.jpg')
        } finally { $buffer.Dispose(); $resized.Dispose(); $source.Dispose() }
    }
    $form.Add([System.Net.Http.StringContent]::new('1024'), 'width')
    $form.Add([System.Net.Http.StringContent]::new('1024'), 'height')
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $response = $client.PostAsync('https://api.cloudflare.com/client/v4/accounts/0111d4c60ec1f60dc6c783f0b62854dd/ai/run/@cf/black-forest-labs/flux-2-klein-4b', $form).GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
    $timer.Stop()
    if (-not $response.IsSuccessStatusCode -or -not $body.result.image) { throw "No image returned. HTTP $([int]$response.StatusCode)." }
    $dir = Join-Path $PSScriptRoot '../build/ai-trial'
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    $bytes = [Convert]::FromBase64String(($body.result.image -replace '^data:image/[^;]+;base64,', ''))
    $ext = if ($bytes[0] -eq 137) { 'png' } elseif ($bytes[0] -eq 255) { 'jpg' } else { 'webp' }
    $output = Join-Path $dir "$OutputName.$ext"
    [IO.File]::WriteAllBytes($output, $bytes)
    Write-Host ('Generated in {0:N1} seconds: {1}' -f $timer.Elapsed.TotalSeconds, [IO.Path]::GetFullPath($output))
    @{ model = '@cf/black-forest-labs/flux-2-klein-4b'; seconds = $timer.Elapsed.TotalSeconds; prompt = $Prompt; reference = $InputImage; output = [IO.Path]::GetFullPath($output) } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir "$OutputName.json")
    $form.Dispose()
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    $secret.Dispose()
    if ($client) { $client.Dispose() }
}
