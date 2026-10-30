<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('idempotency_key')->unique();
            $table->string('type', 20)->index();
            $table->foreignId('student_id')->constrained('students')->restrictOnDelete();
            $table->foreignId('outlet_id')->nullable()->constrained('outlets')->restrictOnDelete();
            $table->foreignId('cashier_shift_id')->nullable()->constrained('cashier_shifts')->restrictOnDelete();
            $table->foreignId('merchant_id')->nullable()->constrained('merchants')->restrictOnDelete();
            $table->decimal('amount', 15, 2);
            $table->decimal('balance_after', 15, 2)->nullable();
            $table->string('reference_type', 50)->nullable();
            $table->string('reference_id', 64)->nullable();
            $table->foreignId('actor_user_id')->nullable()->constrained('users')->restrictOnDelete();
            $table->string('status', 20)->default('posted');
            $table->uuid('reversed_by')->nullable();
            $table->string('note', 255)->nullable();
            $table->index(['student_id', 'created_at']);
            $table->index(['outlet_id', 'created_at']);
            $table->index(['cashier_shift_id', 'created_at']);
            $table->timestamps();
            $table->foreign('reversed_by')->references('id')->on('transactions')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
