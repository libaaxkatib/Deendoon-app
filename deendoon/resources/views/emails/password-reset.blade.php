<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reset your Deendoon password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f5f7; font-family: Arial, Helvetica, sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f5f7; padding: 32px 0;">
        <tr>
            <td align="center">
                <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden;">
                    <tr>
                        <td style="background-color: #1f2937; padding: 20px 32px;">
                            <span style="color: #ffffff; font-size: 20px; font-weight: bold;">Deendoon</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 32px;">
                            <h1 style="font-size: 18px; color: #111827; margin: 0 0 16px;">Reset your password</h1>
                            <p style="font-size: 14px; color: #374151; line-height: 1.6; margin: 0 0 16px;">
                                Hi {{ $name }},
                            </p>
                            <p style="font-size: 14px; color: #374151; line-height: 1.6; margin: 0 0 16px;">
                                We received a request to reset the password for your Deendoon account. Enter the code below in the app to choose a new password.
                            </p>
                            <div style="background-color: #f3f4f6; border-radius: 6px; padding: 16px; text-align: center; margin: 0 0 16px;">
                                <span style="font-size: 20px; letter-spacing: 1px; font-family: 'Courier New', monospace; color: #111827; word-break: break-all;">{{ $token }}</span>
                            </div>
                            <p style="font-size: 13px; color: #6b7280; line-height: 1.6; margin: 0 0 16px;">
                                This code expires in {{ $expiryMinutes }} minutes and can only be used once.
                            </p>
                            <p style="font-size: 13px; color: #6b7280; line-height: 1.6; margin: 0;">
                                If you didn't request a password reset, you can safely ignore this email — your password will not be changed.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 16px 32px; border-top: 1px solid #e5e7eb;">
                            <span style="font-size: 12px; color: #9ca3af;">&copy; {{ date('Y') }} Deendoon. This is an automated message, please do not reply.</span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
