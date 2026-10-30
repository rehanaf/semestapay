<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('item_transaction', function (Blueprint $table) {
            $table->id();
            $table->uuid('transaction_id');
            $table->foreignId('item_id')->constrained('items')->restrictOnDelete();
            $table->unsignedInteger('quantity')->default(1);
            $table->decimal('price', 15, 2);
            $table->timestamps();
            $table->index('transaction_id');
            $table->foreign('transaction_id')->references('id')->on('transactions')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('item_transaction');
    }
};
