CLS
$ErrorActionPreference = "STOP"

$splitString = " @@@ "
$port = 9000
$colors = @{"ERROR" = [ConsoleColor]::Red;
            "FATAL" = [ConsoleColor]::Red;
            "DEBUG" = [ConsoleColor]::White; 
            "WARN" = [ConsoleColor]::Yellow;
            "INFO" = [ConsoleColor]::Gray; }

$levels = @{"ERROR" = "ERR";
            "FATAL" = "FTL";
            "DEBUG" = "DBG";
            "WARN" = "WRN";
            "INFO" = "NFO";}

try 
{
    $endpoint = New-Object Net.IPEndPoint ([IPAddress]::Any, $port)
    $client = New-Object Net.Sockets.UdpClient $port
    
    while($true)  
    {
        $line = [Text.Encoding]::UTF8.GetString($client.Receive([ref]$endpoint))
        
        if($line.IndexOf($splitString) -eq -1)
        {
           continue;
        }
        
        $segments = $line -split $splitString
        $name = $segments[0]
        
        try
        {
            $time = [DateTime]::Parse($segments[1])
        }
        catch
        {   
            $time = [DateTime]::MinValue
        }

        $thread = $segments[2].Replace("Heartbeat", "HB").Replace("ManagedPoolThread #", "MPT#")
        $level = $segments[3]
        $logger = $segments[4]
        $message = $segments[5]
     
        $widestName = @{ $true = $name.Length; $false = $widestName }[$name.Length -gt $widestName]
        $widestThread = @{ $true = $thread.Length; $false = $widestThread }[$thread.Length -gt $widestThread]               
        $color = @{ $true = [ConsoleColor]::Green; $false = $colors[$level] }[$level -eq "INFO" -and $message -match "AUDIT"]
           
        Write-Host ("[{0, -$widestName}] " -f $name) -NoNewline -ForegroundColor Gray
        Write-Host ("{0} " -f $time.ToLongTimeString()) -NoNewline -ForegroundColor Gray
        Write-Host ("[{0}] " -f $levels[$level]) -NoNewline -ForegroundColor $color
        Write-Host ("[{0, -$widestThread}] " -f $thread) -NoNewline -ForegroundColor $color
        Write-Host ("{0}: " -f $logger) -NoNewline -ForegroundColor Gray
        Write-Host ("{0} " -f $message) -NoNewline -ForegroundColor $color          
        Write-Host ""                    
    } 
}
finally 
{
    if($client -ne $null)
    {
        $client.Close()
        $client = $null
    }
}