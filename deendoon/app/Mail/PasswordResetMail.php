<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

/**
 * FR-004's "platform-configured recovery channel" — email, per the task
 * scope for this feature (no SMS/other channel is implemented anywhere
 * else in this project either). Sent synchronously (`Mail::send()`, not
 * `->queue()`), matching every other side effect in this codebase
 * (notifications, document generation, audit logging) — no queued job
 * exists anywhere in this project, so queuing only this one email would
 * be a new, inconsistent pattern rather than following the existing one.
 */
class PasswordResetMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly User $user,
        public readonly string $token,
        public readonly int $expiryMinutes,
    ) {}

    public function build(): self
    {
        return $this->subject('Reset your Deendoon password')
            ->view('emails.password-reset')
            ->with([
                'name' => $this->user->name,
                'token' => $this->token,
                'expiryMinutes' => $this->expiryMinutes,
            ]);
    }
}
