param(
	[string]$pinboardUser = "",
	[DateTime]$linksEndTime = (get-date -Minute 0 -Second 0 -Hour 12 -Millisecond 0),
	[string]$emailFrom = "",
	[string]$emailTo = '',
	[pscredential]$proxyCredentials,
	[string]$smtpServer = "va-mail01.dreamwidth.org",
	[switch]$TestMode
)

$wc = New-Object System.Net.WebClient
if($proxyCredentials){
	$wc.Proxy.Credentials = $proxyCredentials
}
[xml]$feed = $wc.DownloadString("https://feeds.pinboard.in/rss/u:$pinboardUser/")

$items = $feed.rdf.item | ? {[DateTime]::Parse($_.date) -gt $linksEndTime.AddDays(-1)}| ? {[DateTime]::Parse($_.date) -LE $linksEndTime} | sort {[DateTime]::Parse($_.date)}

if($items){
	$tags = @()
	$output = "<dl class=`"links`">"
	foreach($item in $items){
		$output+="<dt class=`"link`"><a href=`"$($item.link)`" rel=`"nofollow`">$($item.Title)</a></dt>"
		$output+="<dd style=`"margin-bottom: 0.5em;`">"
		if($item.Description){
			$output += "<span class=`"link-description`">$($item.description.'#cdata-section')</span><BR/>"
		}
		if($item.subject){
			$output += "<small class=`"link-tags`">(tags:"
			foreach($tag in ($item.subject -split " ")){
				$tags += $tag
				$output += "<A href=`"https://pinboard.in/u:$pinboardUser/t:$tag`">$tag</A> "
			} 
			$output += ")</small>"
		}
		$output += "</dd>"
	}
	$output += "</dl>"
	
	$output += "`n`n--`n`n"
	
	if($tags){
		$tags += "links"
		$tagsHeader = "post-tags: " + (($tags | sort -unique) -join ", ")
		$output = $tagsHeader + "`n`n" + $output
	}

	$subjectLink = "Interesting Links for $($linksEndTime.ToString("dd-MM-yyyy"))"

	$output = $output -replace "‘|’","'"
	$output = $output -replace '–',"-"
	$output = $output -replace "`“|`”",'"'
	
	if($TestMode){
		$output
	}
	else{
		Send-MailMessage -From $emailFrom -To $emailTo -Subject $subjectLink -Body $output -SmtpServer $smtpServer
	}
}

