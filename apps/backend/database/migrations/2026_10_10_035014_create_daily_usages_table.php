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
            $table->date('usage_date');
            $table->decimal('total_used', 15, 2)->default(0);
            $table->unique(['student_id', 'usage_date']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_usages');
    }
};
