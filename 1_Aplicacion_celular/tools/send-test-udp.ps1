param(
    [string]$Destination = '255.255.255.255',
    [int]$Port = 4210,
    [ValidateSet('OK', 'CHARGING', 'LOW_BATTERY', 'OVER_RANGE')]
    [string]$State = 'OK',
    [int]$Count = 100,
    [int]$DelayMs = 350
)
# Synthetic readings will be uploaded if automatic upload is enabled in the app.
$udp = New-Object System.Net.Sockets.UdpClient
$udp.EnableBroadcast = $true
$endpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Parse($Destination)), $Port
try {
    for ($i = 0; $i -lt $Count; $i++) {
        $seq = $i % 65536
        $fields = switch ($State) {
            'CHARGING' { '2610,830,0,0' }
            'LOW_BATTERY' { '2320,0,1,0' }
            'OVER_RANGE' { '2610,4095,1,1' }
            default { '2610,830,1,1' }
        }
        $line = "D:$seq,$fields`n"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($line)
        [void]$udp.Send($bytes, $bytes.Length, $endpoint)
        Write-Output $line.TrimEnd()
        Start-Sleep -Milliseconds $DelayMs
    }
} finally { $udp.Dispose() }
