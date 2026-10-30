<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cashiers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('outlet_id')->constrained('outlets')->restrictOnDelete();
            $table->string('status', 20)->default('active')->index();
            $table->timestamps();
            $table->unique(['user_id', 'outlet_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cashiers');
    }
};
