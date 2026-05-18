namespace osafw;

public interface INotification
{
    public NotificationResponse SendNotification(NotificationRequest request);

}

