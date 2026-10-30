<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('nis', 30)->unique();
            $table->string('name', 150);
            $table->foreignId('class_id')->nullable()->constrained('classes')->restrictOnDelete();
            $table->string('phone_parent', 20)->nullable();
            $table->string('pin_hash', 255)->nullable();
            $table->string('status', 20)->default('active')->index();

            $table->string('card_uid', 64)->nullable()->unique();
            $table->string('card_status', 20)->default('active')->index();
            $table->timestamp('card_assigned_at')->nullable();

            $table->decimal('balance', 15, 2)->default(0);
            $table->char('currency', 3)->default('IDR');
            $table->string('wallet_status', 20)->default('active')->index();
            $table->timestamp('balance_updated_at')->nullable();
            $table->unsignedBigInteger('version')->default(0);
            $table->decimal('daily_limit', 15, 2)->default(0);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('students');
    }
};
