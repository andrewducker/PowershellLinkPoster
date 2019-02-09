# PowershellLinkPoster
Powershell Link Poster - Pinboard to Delicious

Note: This runs under PowerShell, which comes as default in Windows 10, and is available for Mac and Linux.  It uses the Dreamwidth "Post by Email" functionality.

Run with a command-line like:

`postlinks.ps1 -pinboardUser andrewducker -emailFrom andrew@ducker.org.uk -emailTo andrewducker+1234@post.dreamwidth.org`

You will need to set up post by email at https://www.dreamwidth.org/manage/emailpost and then update the command line to match your settings.

You can run it with a TestMode flag, which will show the results rather than posting them.

i.e. `postlinks.ps1 -pinboardUser andrewducker -emailFrom andrew@ducker.org.uk -emailTo andrewducker+1234@post.dreamwidth.org -TestMode`

If you're inside a corporate firewall then you will probably need to set the ProxyCredentials parameter.  And unless you have external SMTP access you'll need an internal mail server (use the "smtpServer" parameter).

All suggestions/merge requests gratefully received.
