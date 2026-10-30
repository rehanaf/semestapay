<?php

namespace App\Http\Requests\Api\v1;

use Illuminate\Foundation\Http\FormRequest;

class TopupRequest extends FormRequest
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
            'student_id' => ['required', 'integer', 'exists:students,id'],
            'amount' => ['required', 'numeric', 'min:1'],
            'method' => ['required', 'in:cash,transfer,va,adjustment'],
            'reference' => ['nullable', 'string', 'max:100'],
            'received_by' => ['nullable', 'integer', 'exists:users,id'],
            'idempotency_key' => ['required', 'uuid'],
        ];
    }
}
