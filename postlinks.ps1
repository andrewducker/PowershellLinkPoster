[CmdletBinding()]
param(
	[string]$pinboardUser = "",
	[DateTime]$linksEndTime = (get-date -Minute 0 -Second 0 -Hour 12 -Millisecond 0),
	[int]$daysPrevious,
	[string]$emailFrom = "",
	[string]$emailTo = '',
	[pscredential]$proxyCredentials,
	[string]$smtpServer = "va-mail01.dreamwidth.org",
	[switch]$TestMode,
	[switch]$NumberEntries
)

$pinboardUrl = "https://feeds.pinboard.in/rss/u:$pinboardUser/"
Write-Verbose "Fetching from $pinboardUrl"
$response = (Invoke-WebRequest $pinboardUrl -ProxyCredential $proxyCredentials).Content

#Unmangle the response.  Powershell resorts to the wrong encoding.  *sigh*
[xml]$feed = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(28591).GetBytes($response))

Write-Verbose "Feed has $($feed.rdf.item.count) entries"

if($daysPrevious){
	$linksEndTime = $linksEndTime.AddDays(-$daysPrevious)
}

Write-Verbose "Selecting links for 24 hours preceding $linksendTime"

$items = $feed.rdf.item | select link,title,description,subject, @{n="date"; e={[DateTime]::Parse($_.date).AddHours(0)}}

$items = $items | ? date -gt $linksEndTime.AddDays(-1)| ? date -LE $linksEndTime | sort date

$itemCount = 0
if($items){
	if($items.count){
		$itemCount = $items.Count
	}
	else{
		$itemCount = 1
	}
}

Write-Verbose "$itemCount items selected"

if($items){
	$tags = @()
	$output = "<dl class=`"links`">"
	$number = 1
	foreach($item in $items){
		$title = $item.title
		if($NumberEntries){
			$title = "$number. $title"
			$number++
		}
		$output+="<dt class=`"link`"><a href=`"$($item.link)`" rel=`"nofollow`">$Title</a></dt>"
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
	
	$output += "`n`n--`n`nDeletetionTrigger"
	
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
		Send-MailMessage -From $emailFrom -To $emailTo -Subject $subjectLink -Body $output -SmtpServer $smtpServer -encoding UTF8
	}
}

