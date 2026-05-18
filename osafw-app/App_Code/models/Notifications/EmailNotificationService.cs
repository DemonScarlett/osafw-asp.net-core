using MailKit.Net.Smtp;
using Microsoft.IdentityModel.Tokens;
using MimeKit;
using System;
using System.Linq;
using System.Text.RegularExpressions;

namespace osafw;

public class EmailNotificationService : FwModel, INotification
{
    //TODO Kate: get rid of FwModel inheritance. Add Vlad's updates
    public NotificationResponse SendNotification(NotificationRequest request)
    {
        var response = new NotificationResponse();

        var message = new MimeMessage();
        var builder = new BodyBuilder();

        try
        {
            if (request.From == null || string.IsNullOrEmpty(request.From.Email))
            {
                request.From = new EmailDTO
                {
                    Email = fw.config("mail_from").toStr()
                };
            }

            logger(LogLevel.INFO, $"Sending email. From=[{request.From}], ReplyTo=[{request.ReplyTo}], To=[{request.To}], Subj=[{request.Subject}]");
            logger(LogLevel.DEBUG, request.Body);

            if (request.To.IsNullOrEmpty())
            {
                logger(LogLevel.ERROR, "send_email error: No email receiver");
                response.ErrorMsg = "No email receiver";

                return response;
            }

            request.Subject = Regex.Replace(request.Subject ?? string.Empty, @"[\r\n]+", " ");
            bool isTest = fw.config("is_test").toBool();

            if (isTest)
            {
                request.Body += $"\nTEST SEND. PASSED MAIL_TO=[{request.To.Select(to => $"{to.Email} ")}]"; //add to the end of the body to preserve html
                request.To = GetTestEmail();

                fw.logger(LogLevel.INFO, $"EMAIL SENT TO TEST EMAIL [{request.To[0].Email}] - TEST ENABLED IN web.config");
            }


            if (request.Options != null && request.Options.ContainsKey("read-receipt"))
            {
                message.Headers.Add("Disposition-Notification-To", request.From.Email);
            }

            if (Regex.IsMatch(request.Body, @"^\s*<(!DOCTYPE|html)[^>]*>", RegexOptions.IgnoreCase))
            {
                builder.HtmlBody = request.Body;
            }
            else
            {
                builder.TextBody = request.Body;
            }

            foreach (var to in request.To)
            {
                if (string.IsNullOrEmpty(to?.Email))
                {
                    logger(LogLevel.ERROR, $"send_email error: Receiver {to?.UserName} doesn`t have email");

                    response.ErrorMsg += $"\nReceiver {to?.UserName} doesn`t have email";
                }
                else
                {
                    message.To.Add(new MailboxAddress(to.UserName, to.Email));
                }
            }

            message.From.Add(new MailboxAddress(request.From.UserName, request.From.Email));
            message.Subject = request.Subject;
            message.Body = builder.ToMessageBody();

            if (!string.IsNullOrEmpty(request.ReplyTo))
            {
                message.ReplyTo.Add(new MailboxAddress(null, request.ReplyTo));
            }

            if (!string.IsNullOrEmpty(request.Cc))
            {
                if (isTest)
                {
                    logger(LogLevel.INFO, $"TEST SEND. PASSED CC=[{request.Cc}]");

                    foreach (var to in request.To)
                    {
                        if (!string.IsNullOrEmpty(to?.Email))
                        {
                            message.Cc.Add(new MailboxAddress(to.UserName, to.Email));
                        }
                    }
                }
                else
                {
                    var ccList = Utils.splitEmails(request.Cc);

                    foreach (string cc in ccList)
                    {
                        message.Cc.Add(new MailboxAddress(null, cc.Trim()));
                    }
                }
            }

            if (!string.IsNullOrEmpty(request.Bcc))
            {
                if (!isTest)
                {
                    var bccList = Utils.splitEmails(request.Bcc);

                    foreach (string bcc in bccList)
                    {
                        message.Bcc.Add(new MailboxAddress(null, bcc.Trim()));
                    }
                }
            }

            // attach attachments if any
            if (request.Filenames != null)
            {
                // sort by human name
                StrList fkeys = [.. request.Filenames.Keys.Cast<string>()];
                fkeys.Sort();
                foreach (string human_filename in fkeys)
                {
                    string filename = request.Filenames[human_filename].toStr();
                    builder.Attachments.Add(filename);

                    logger(LogLevel.DEBUG, "attachment ", human_filename, " => ", filename);
                }

                using (var client = new SmtpClient())
                {
                    FwDict mailSettings = fw.config("mail") as FwDict ?? [];
                    if (request.Options != null  && request.Options.TryGetValue("smtp", out object? value) && value is FwDict smtpOptions)
                    {
                        //override mailSettings from smtp options
                        Utils.mergeHash(mailSettings, smtpOptions);
                    }
                    if (mailSettings.Count > 0)
                    {
                        var host = mailSettings["host"].toStr();
                        var port = mailSettings["port"].toInt();
                        var enableSsl = mailSettings["is_ssl"].toBool();
                        var username = mailSettings["username"].toStr();
                        var password = mailSettings["password"].toStr();

                        client.Connect(host, port, enableSsl);

                        client.Authenticate(username, password);

                        client.Send(message);
                        client.Disconnect(true);
                    }
                }
            }
        }
        catch(Exception ex)
        {
            response.Result = false;
            response.ErrorMsg = ex.Message;

            if (ex.InnerException != null)
            {
                response.ErrorMsg += " " + ex.InnerException.Message;
            }

            logger(LogLevel.ERROR, $"send_email error: {response.ErrorMsg}");
        }
        finally
        {
            if (message != null)
            {
                //var mail_to_first = message.To.Any() ? message.To[0].Address : mail_to;
                //var mail_to_iname = message.To.Any() ? message.To[0].DisplayName : "";
                //var mail_to_cc = message.CC.Any() ? message.CC[0].Address : "";
                //var is_error = !emailResponse.Result;
                //emailResponse.ErrorMsg = last_error_send_email;
                //emailResponse.EmailLogId = this.model<EmailLog>().add(mail_from, "", mail_to_first, mail_to_iname, mail_to_cc, mail_subject, mail_body, is_test, is_log_only, is_error, emailResponse.ErrorMsg);

                message.Dispose();
            }
        }

        return response;
    }

    private List<EmailDTO> GetTestEmail()
    {
        var testEmails = new List<EmailDTO>();
        string emails = fw.Session("login") ?? ""; //in test mode - try logged user email (if logged)

        if (string.IsNullOrEmpty(emails))
        {
            emails = fw.config("test_email").toStr(); //try test_email from config
        }

        var emailsList = Utils.splitEmails(emails);

        foreach (var email in emailsList)
        {
            var testEmail = new EmailDTO()
            {
                Email = email
            };

            testEmails.Add(testEmail);
        }

        return testEmails;
    }
        
}

