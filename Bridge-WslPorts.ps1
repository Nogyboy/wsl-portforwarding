$ports = @(80, 443, 5173, 5174);

$wslAddress = bash.exe -c "ip a | grep -oP '(?<=inet\s)(?!127\.0\.0\.1)[\d.]+' | awk 'NR==1'"

if ($wslAddress -match '^(\d{1,3}\.){3}\d{1,3}$') {
  Write-Host "WSL IP address: $wslAddress" -ForegroundColor Green
  Write-Host "Ports: $ports" -ForegroundColor Green
}
else {
  Write-Host "Error: Could not find WSL IP address." -ForegroundColor Red
  exit
}

$listenAddress = '0.0.0.0';

foreach ($port in $ports) {
  Invoke-Expression "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$listenAddress";
  Invoke-Expression "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$listenAddress connectport=$port connectaddress=$wslAddress";
}

$fireWallDisplayName = '"WSL2 Port Bridge"';
$portsStr = $ports -join ",";

Invoke-Expression "Remove-NetFireWallRule -DisplayName $fireWallDisplayName";
Invoke-Expression "New-NetFireWallRule -DisplayName $fireWallDisplayName -Direction Outbound -Action Allow -Protocol TCP -LocalPort $portsStr";
Invoke-Expression "New-NetFireWallRule -DisplayName $fireWallDisplayName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $portsStr";

# Print port forwarded
Invoke-Expression "netsh interface portproxy show v4tov4"
