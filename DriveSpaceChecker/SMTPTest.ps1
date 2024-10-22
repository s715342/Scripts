$emailSmtpServer = "smtp-relay.wexinc.com"
$emailFrom = "donotreply@wexinc.com"
$emailTo = "matthew.sly@wexinc.com"
$emailSubject = "Testing - auw2toolsn001p"
$emailBody = "Drive Checker - test"

Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $emailBody -SmtpServer $emailSmtpServer