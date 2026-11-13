<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_usages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignId('merchant_id')->nullable()->constrained('merchants')->nullOnDelete();
            $table->date('usage_date');
            $table->decimal('total_used', 15, 2)->default(0);
            $table->unique(['student_id', 'merchant_id', 'usage_date'], 'daily_usages_student_merchant_date_unique');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_usages');
    }
};
