<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('virtual_accounts', function (Blueprint $table) {
            $table->boolean('is_static')->default(false)->after('status')->index();
        });

        // Set semua VA yang sudah ada sebagai static VA
        DB::table('virtual_accounts')->update(['is_static' => true]);
    }

    public function down(): void
    {
        Schema::table('virtual_accounts', function (Blueprint $table) {
            $table->dropIndex(['is_static']);
            $table->dropColumn('is_static');
        });
    }
};
