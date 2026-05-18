namespace osafw;

public class NotificationResponse
{
    public bool Result { get; set; }
    public int NotificationLogId { get; set; }
    public string ErrorMsg { get; set; } = string.Empty;
}