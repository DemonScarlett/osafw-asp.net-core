DROP TABLE IF EXISTS notification_recipients;
CREATE TABLE notification_recipients (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  users_id              INT NOT NULL CONSTRAINT FK_notification_recipients_users FOREIGN KEY REFERENCES users(id), -- add more FK fields for other sender tables

  status                TINYINT NOT NULL DEFAULT 0,
  add_time              DATETIME2 NOT NULL DEFAULT getdate(),
  add_users_id          INT DEFAULT 0,
  upd_time              DATETIME2,
  upd_users_id          INT DEFAULT 0
);

DROP TABLE IF EXISTS event_initiator_types;
CREATE TABLE event_initiator_types (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  iname                 NVARCHAR(64) NOT NULL DEFAULT '',
  idesc                 NVARCHAR(MAX), 
  icode                 NVARCHAR(64) NOT NULL,
  prio                  TINYINT NOT NULL DEFAULT 0,

  INDEX UX_event_initiator_types_icode UNIQUE (icode)
);

DROP TABLE IF EXISTS notification_types;
CREATE TABLE notification_types (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  iname                 NVARCHAR(64) NOT NULL DEFAULT '',
  idesc                 NVARCHAR(MAX), 
  icode                 NVARCHAR(64) NOT NULL,
  prio                  TINYINT NOT NULL DEFAULT 0,

  add_time              DATETIME2 NOT NULL DEFAULT getdate(),
  add_users_id          INT DEFAULT 0,

  INDEX UX_notification_types_icode UNIQUE (icode)
);

DROP TABLE IF EXISTS notification_statuses;
CREATE TABLE notification_statuses (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  iname                 NVARCHAR(64) NOT NULL DEFAULT '',
  idesc                 NVARCHAR(MAX), 
  icode                 NVARCHAR(64) NOT NULL,

  INDEX UX_notification_statuses_icode UNIQUE (icode)
);

GO

DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
  id                            INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  sender_initiator_id           INT NULL CONSTRAINT FK_notifications_users FOREIGN KEY REFERENCES users(id),
  initiator_type_id             INT NOT NULL CONSTRAINT FK_notifications_event_initiator_types FOREIGN KEY REFERENCES event_initiator_types(id),
  sender_credential             NVARCHAR(120) NOT NULL DEFAULT '',
  cc_credentials                NVARCHAR(4000), 
  bcc_credentials               NVARCHAR(4000),
  recipient_credential          NVARCHAR(120) NOT NULL DEFAULT '',
  notification_recipients_id    INT NOT NULL CONSTRAINT FK_notifications_notification_recipients FOREIGN KEY REFERENCES notification_recipients(id),

  notification_types_id         INT NOT NULL CONSTRAINT FK_notifications_notification_types FOREIGN KEY REFERENCES notification_types(id),
  subject                       NVARCHAR(512),
  body                          NVARCHAR(MAX),
  metadata                      NVARCHAR(MAX),
  is_test                       TINYINT NOT NULL DEFAULT 0,
  is_log_only                   TINYINT NOT NULL DEFAULT 0,
  notification_statuses_id      INT NOT NULL CONSTRAINT FK_notifications_notification_statuses FOREIGN KEY REFERENCES notification_statuses(id),
  status_error_msg              NVARCHAR(4000),


  status                TINYINT NOT NULL DEFAULT 0,
  add_time              DATETIME2 NOT NULL DEFAULT getdate(),
  add_users_id          INT DEFAULT 0,
  upd_time              DATETIME2,
  upd_users_id          INT DEFAULT 0,

  INDEX IX_notifications_recipient_credential (recipient_credential),
  INDEX IX_notifications_recipient_notification_recipients_id (notification_recipients_id),
  INDEX IX_notifications_sender_initiator_id (sender_initiator_id),
  INDEX IX_notifications_initiator_type_id (initiator_type_id),
  INDEX IX_notifications_sender_credential (sender_credential),
);

GO

DROP TABLE IF EXISTS notifications_atts;
CREATE TABLE notifications_atts (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  notifications_id      INT NOT NULL CONSTRAINT FK_notifications_atts_notifications FOREIGN KEY REFERENCES notifications(id),
  atts_id               INT NOT NULL CONSTRAINT FK_notifications_atts_att FOREIGN KEY REFERENCES att(id),

  add_time              DATETIME2 NOT NULL DEFAULT getdate()
);

DROP TABLE IF EXISTS activity_logs_message_log;
CREATE TABLE activity_logs_message_log (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  notifications_id      INT NOT NULL CONSTRAINT FK_activity_logs_message_log_notifications FOREIGN KEY REFERENCES notifications(id),
  activity_logs_id      INT NOT NULL CONSTRAINT FK_activity_logs_message_log_activity_logs FOREIGN KEY REFERENCES activity_logs(id),

  add_time              DATETIME2 NOT NULL DEFAULT getdate()
);

DROP TABLE IF EXISTS notifications_queue;
CREATE TABLE notifications_queue (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  notifications_id      INT NOT NULL CONSTRAINT FK_notifications_queue_notifications FOREIGN KEY REFERENCES notifications(id),
  attempts              TINYINT NOT NULL DEFAULT 0,
  next_attempt_time     DATETIME2,
  schedule_date         DATETIME2,

  add_time              DATETIME2 NOT NULL DEFAULT getdate()
);

DROP TABLE IF EXISTS notifications_log;
CREATE TABLE notifications_log (
  id                    INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,

  notifications_id      INT NOT NULL CONSTRAINT FK_notifications_log_notifications FOREIGN KEY REFERENCES notifications(id),
  sent_date             DATETIME2,

  add_time              DATETIME2 NOT NULL DEFAULT getdate()
);


-- INSERT

INSERT INTO event_initiator_types (iname, idesc, icode)
VALUES ('User', 'Autorized user', 'user'),
       ('System', 'Automatic notification triggered by event', 'system'),
       ('Cron', 'Scheduled notification', 'cron');

INSERT INTO notification_types (iname, idesc, icode)
VALUES ('Email', 'Email notification', 'email'),
       ('Push', 'Push notification', 'push'),
       ('Sms', 'Sms notification', 'sms');

INSERT INTO notification_statuses (iname, idesc, icode)
VALUES ('In queue', 'Created and placed in queue', 'queue'),
       ('Sent', 'Sent to receiver', 'sent'),
       ('Cancelled', 'Cancelled', 'cancelled'),
       ('Schedulled', 'In queue but with schedule date', 'schedule'),
       ('Error', 'In queue, but there was with errors', 'error'),
       ('Failed', 'Cancelled because attempts have run out', 'failed');

INSERT INTO log_types (itype, icode, iname)
  VALUES (0, 'notification_sent', 'Notification Sent'),
         (0, 'notification_queue', 'Notification Added To Queue'),
         (0, 'notification_canceled', 'Notification Canceled');