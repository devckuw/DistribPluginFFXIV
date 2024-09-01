$pluginsOut = @()

$username = "devckuw"

# Authorization header for the Github API.
$header = @{
  "Authorization" = "Bearer $env:GITHUB_TOKEN"
}

$repos = @("combatHelper")

foreach ($repo in $repos)
{
	# Fetch the release data from the Gibhub API
	$data = Invoke-WebRequest -Uri "https://api.github.com/repos/$($username)/$($repo)/releases/latest" -Headers $header
	$json = ConvertFrom-Json $data.content
	$asset = $json.assets

	# Get data from the api request.
	$count = $asset.download_count
	$download = $asset.browser_download_url

	# Get timestamp for the release.
	$time = [Int](New-TimeSpan -Start (Get-Date "01/01/1970") -End ([DateTime]$json.published_at)).TotalSeconds

	# Download the zip file.
	Invoke-WebRequest -Uri $download -OutFile "tmp.zip"
	Expand-Archive -Path "tmp.zip" -DestinationPath "tmp" -Force

	# Load the json from the release.zip
	$config = Get-Content -Path "TMP/$repo.json" | Out-String | ConvertFrom-Json

	# remove tmp files
	Remove-Item -Path "tmp.zip" -Force
	Remove-Item -Path "TMP" -Force -Recurse


	# Add additional properties to the config.
	$config | Add-Member -Name "IsHide" -MemberType NoteProperty -Value "False"
	$config | Add-Member -Name "IsTestingExclusive" -MemberType NoteProperty -Value "False"
	$config | Add-Member -Name "LastUpdated" -MemberType NoteProperty -Value $time
	$config | Add-Member -Name "DownloadCount" -MemberType NoteProperty -Value $count
	$config | Add-Member -Name "DownloadLinkInstall" -MemberType NoteProperty -Value $download
	$config | Add-Member -Name "DownloadLinkTesting" -MemberType NoteProperty -Value $download
	$config | Add-Member -Name "DownloadLinkUpdate" -MemberType NoteProperty -Value $download


	# Add to the plugin array.
	$pluginsOut += $config
}

# Convert plugins to JSON
$pluginJson = ConvertTo-Json $pluginsOut

# Save repo to file
Set-Content -Path "repo.json" -Value $pluginJson

# Function to exit with a specific code.
function ExitWithCode($code) {
  $host.SetShouldExit($code)
  exit $code
}
