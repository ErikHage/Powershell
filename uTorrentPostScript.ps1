param (
    [string]$u = "",
    [string]$p = "",
	[string]$port = ""

 )
 #Write-Output "user = $($u)"
 #Write-Output "pass = $($p)"

$UTORRENT_URL = "http://localhost:$($port)/gui/"
$REGEX_UTORRENT_TOKEN = 
@"
<div[^>]*id=[\"\']token[\"\'][^>]*>([^<]*)</div>
"@

$webclient = new-object System.Net.WebClient
$credCache = new-object System.Net.CredentialCache
$creds = new-object System.Net.NetworkCredential($u,$p)
$credCache.Add($UTORRENT_URL, "Basic", $creds)
$webclient.Credentials = $credCache
$webpage = $webclient.DownloadString($UTORRENT_URL+ "token.html")
$cookies =  $webClient.ResponseHeaders["Set-Cookie"]
$webclient.Headers.Add("Cookie",$cookies)

$webpage -match $REGEX_UTORRENT_TOKEN > $null
$token = $matches[1]

#$UTORRENT_TOKENIZED_URL = $UTORRENT_URL + "?list=1&token=" + $token
$UTORRENT_TOKENIZED_URL = $UTORRENT_URL + "?token=$($token)"

$response = $webClient.DownloadString($UTORRENT_URL + "?list=1&token=" + $token)
$json = ConvertFrom-JSON $response

#$dict=@{}
    
$json.torrents | Foreach-Object {
    #$dict.add($_[2],$_)
    if($_[21].startswith("Finished") -or $_[21].startswith("Seeding") -or $_[21].startswith("Queued seed")){
            #Write-Output "Removing the Following Torrent: "
            #Write-Output "Name: $($_[2])"
            #Write-Output "Hash: $($_[0])"
            #Write-Output "Status: $($_[21])"
            #Write-Output "Path: $($_[26])"
            $current_url = $UTORRENT_TOKENIZED_URL+"&action=remove&hash=$($_[0])"
            $response = $webClient.DownloadString($current_url)
            [string]$fullPath = $_[26]
            [string]$name = $_[2]
            $path = $fullPath.Substring(0,$fullPath.Length-$name.Length)
            $path
            rm -Path ($path+"*") -Include *.torrent
    }
} 