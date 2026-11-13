<?php

namespace App\Models;

use App\Enums\VirtualAccountStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'student_id', 'provider', 'payment_code', 'bank_name', 'account_number',
    'merchant_order_id', 'provider_reference', 'amount', 'status', 'payment_url',
    'expires_at', 'paid_at', 'request_payload', 'response_payload',
    'callback_payload', 'metadata',
])]
class VirtualAccount extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'expires_at' => 'datetime',
            'paid_at' => 'datetime',
            'request_payload' => 'array',
            'response_payload' => 'array',
            'callback_payload' => 'array',
            'metadata' => 'array',
        ];
    }

    /**
     * @return BelongsTo<Student, $this>
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function isPaid(): bool
    {
        return $this->status === VirtualAccountStatus::Paid->value;
    }

    public function isPending(): bool
    {
        return $this->status === VirtualAccountStatus::Pending->value;
    }
}
