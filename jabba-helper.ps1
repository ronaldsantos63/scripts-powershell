# Adicionar o script abaixo no $PROFILE
# notepad $PROFILE
function List-JDKs {
    $from = "$env:USERPROFILE\.jabba\jdk"
    Get-ChildItem -Directory -Path $from | ForEach-Object {
        Write-Output $_.Name
    }
}

function Use-JDK {
    param (
        [string]$name
    )
    $from = "$env:USERPROFILE\.jabba\jdk"
    $jdks = Get-ChildItem -Directory -Path $from

    if (-not $name) {
        # Exibir uma lista interativa para o usuário selecionar o JDK
        Write-Output "Select a JDK from the list below:"
        for ($i = 0; $i -lt $jdks.Count; $i++) {
            Write-Output "${i}: $($jdks[$i].Name)"
        }
        
        $selectedIndex = Read-Host "Enter the index of the JDK you want to use"
        $selectedJDK = $jdks[$selectedIndex]
    } else {
        # Selecionar o JDK pelo nome fornecido
        $selectedJDK = $jdks | Where-Object { $_.Name -eq $name }
    }

    if ($selectedJDK) {
        $location = $selectedJDK.FullName
        Write-Output "Selected option: $($selectedJDK.Name) from location: $location"
        Set-JDKPaths -location $location
    } else {
        Write-Output "JDK with name '$name' not found."
    }
}

function Set-JDKPaths {
    param (
        [string]$location
    )
    Write-Output "Setting the paths for current user only"
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $location, [System.EnvironmentVariableTarget]::User)

    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $updatedPath = ""

    $pathList = $currentPath -split ";"
    foreach ($path in $pathList) {
        if ($path -notmatch "\\.jabba\\jdk") {
            if ($updatedPath -eq "") {
                $updatedPath = $path
            } else {
                $updatedPath += ";$path"
            }
        }
    }

    $updatedPath = "$location\bin;$updatedPath"
    [System.Environment]::SetEnvironmentVariable("Path", $updatedPath, [System.EnvironmentVariableTarget]::User)

    # Persist the updated PATH in the registry
    $regPath = "HKCU:\Environment"
    Set-ItemProperty -Path $regPath -Name "Path" -Value $updatedPath

    Write-Output "JAVA_HOME and PATH updated to the selected values for current user"

    # Update the current session environment variables
    $env:JAVA_HOME = $location
    $env:Path = $updatedPath

    Write-Output "Terminal session updated to reflect the new JAVA_HOME and PATH"
}

function Sdk {
    param (
        [string]$command,
        [string]$name
    )

    switch ($command) {
        "ls" { List-JDKs }
        "use" { Use-JDK -name $name }
        default { Write-Output "Please enter a valid value" }
    }
}
