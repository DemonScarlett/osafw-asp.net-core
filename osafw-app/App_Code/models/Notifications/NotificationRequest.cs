using System.Collections;

namespace osafw;

public class NotificationRequest
{
    public EmailDTO? From { get; set; }
    public required List<EmailDTO> To { get; set; }
    public string? Subject { get; set; }
    public required string Body { get; set; }
    public IDictionary? Filenames { get; set; }
    public string? Cc { get; set; }
    public string? Bcc { get; set; }
    public string? ReplyTo { get; set; }
    public FwDict? Options { get; set; }
}

