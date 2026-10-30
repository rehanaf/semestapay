<?php

namespace App\Http\Requests\Api\v1;

use Illuminate\Foundation\Http\FormRequest;

class TapPaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'card_uid' => ['required', 'string', 'max:64', 'exists:students,card_uid'],
            'outlet_code' => ['required', 'string', 'max:30', 'exists:outlets,code'],
            'amount' => ['required', 'numeric', 'min:1'],
            'note' => ['nullable', 'string', 'max:255'],
            'pin' => ['nullable', 'string', 'digits:6'],
            'items' => ['nullable', 'array', 'max:20'],
            'items.*.item_id' => ['required', 'integer', 'exists:items,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'idempotency_key' => ['required', 'uuid'],
        ];
    }
}
