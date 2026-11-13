<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('students', function (Blueprint $table) {
            // Tempat lahir (birth_date sudah ada)
            $table->string('birth_place')->nullable()->after('birth_date');

            // Agama
            $table->string('religion')->nullable()->after('birth_place');

            // Status pernikahan
            $table->string('marital_status')->nullable()->after('religion');

            // Nomor telepon santri sendiri (phone_parent sudah ada untuk ortu)
            $table->string('phone')->nullable()->after('marital_status');
        });
    }

    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            $table->dropColumn(['birth_place', 'religion', 'marital_status', 'phone']);
        });
    }
};
