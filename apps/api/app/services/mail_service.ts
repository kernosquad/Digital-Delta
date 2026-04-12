import { Resend } from 'resend';

import env from '#start/env';

const resend = new Resend(env.get('RESEND_API_KEY'));

const FROM = `${env.get('MAIL_FROM_NAME')} <${env.get('MAIL_FROM_ADDRESS')}>`;

export class MailService {
  async sendVerificationEmail(email: string, name: string, code: string): Promise<void> {
    await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Verify your Digital Delta account',
      html: `
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f8;padding:40px 0;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08);">
        <!-- Header -->
        <tr>
          <td style="background:#1a2e4a;padding:28px 40px;">
            <p style="margin:0;color:#ffffff;font-size:20px;font-weight:700;letter-spacing:.5px;">
              &#9650; Digital Delta
            </p>
            <p style="margin:4px 0 0;color:#7fa8cc;font-size:12px;text-transform:uppercase;letter-spacing:1px;">
              Disaster Response Logistics
            </p>
          </td>
        </tr>
        <!-- Body -->
        <tr>
          <td style="padding:40px 40px 32px;">
            <p style="margin:0 0 8px;font-size:22px;font-weight:600;color:#1a2e4a;">
              Verify your email
            </p>
            <p style="margin:0 0 28px;font-size:15px;color:#4a5568;line-height:1.6;">
              Hi ${name}, welcome to Digital Delta. Use the code below to verify your account.
              This code expires in <strong>15 minutes</strong>.
            </p>
            <!-- Code box -->
            <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
              <tr>
                <td style="background:#f0f4f8;border:2px solid #1a2e4a;border-radius:8px;padding:18px 40px;text-align:center;">
                  <span style="font-size:36px;font-weight:700;letter-spacing:12px;color:#1a2e4a;font-family:monospace;">
                    ${code}
                  </span>
                </td>
              </tr>
            </table>
            <p style="margin:0;font-size:13px;color:#718096;">
              POST this code to <code style="background:#f0f4f8;padding:2px 6px;border-radius:4px;">/api/auth/verify-email</code>
              with body <code style="background:#f0f4f8;padding:2px 6px;border-radius:4px;">{ "code": "${code}" }</code>.
            </p>
          </td>
        </tr>
        <!-- Footer -->
        <tr>
          <td style="background:#f8fafc;border-top:1px solid #e2e8f0;padding:20px 40px;">
            <p style="margin:0;font-size:12px;color:#a0aec0;">
              If you did not create a Digital Delta account, you can safely ignore this email.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
      `.trim(),
    });
  }
}
