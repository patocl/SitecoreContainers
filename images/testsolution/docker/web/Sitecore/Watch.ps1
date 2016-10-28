[CmdletBinding()]
param(
    # Path to watch for changes
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    $Path,
    # Destination path to keep updated
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    $Destination,
    # Array of filename patterns (-like operator) to ignore
    [Parameter(Mandatory=$false)]
    [array]$Ignore = @("*\obj\*", "*.cs", "*.csproj")
)

$Destination = $Destination.TrimEnd("\")

Write-Host ("{0}: Watching '{1}' for changes, will copy to '{2}' while ignoring '{3}'..." -f [DateTime]::Now.ToString("s"), $Path, $Destination, ($Ignore -join ", "))
              
while($true)
{   
    Get-ChildItem -Path $Path -Recurse -File | % {
        $sourcePath = $_.FullName
        $targetPath = ("{0}\{1}" -f $Destination, $_.FullName.Replace("$Path\", ""))  
        $ignored = $false
        
        if($Ignore -ne $null -and $Ignore.Length -gt 0) {
            :filter foreach($filter in $Ignore) {
                if($sourcePath -like $filter)
                {                    
                    $ignored = $true
                    break :filter
                }
            }                
        }

        if($ignored -eq $false)
        {
            $triggerReason = $null

            if(Test-Path -Path $targetPath -PathType Leaf) 
            {
                Compare-Object (Get-Item $sourcePath) (Get-Item $targetPath) -Property Name, Length, LastWriteTime | % {
                    $triggerReason = "Different"
                }
            }
            else
            {
                $triggerReason = "Missing"
            }

            if($triggerReason -ne $null)
            {
                New-Item -Path (Split-Path $targetPath) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
               
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
               
                Write-Host ("{0}: {1, -9} -> {2, -9}" -f [DateTime]::Now.ToString("s"), $triggerReason, $sourcePath)
            }
        }
    }    

    Sleep -Milliseconds 500
}