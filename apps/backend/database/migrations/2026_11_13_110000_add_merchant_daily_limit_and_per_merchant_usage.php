<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Tambah daily_limit per merchant (null = tidak ada batas)
        Schema::table('merchants', function (Blueprint $table) {
            if (! Schema::hasColumn('merchants', 'daily_limit')) {
                $table->unsignedBigInteger('daily_limit')->nullable()->after('balance')
                    ->comment('Batas belanja harian per siswa di merchant ini. NULL = tidak dibatasi.');
            }
        });

        // Kolom merchant_id & unique constraint baru sudah ditangani di create_daily_usages_table.
        // Migration ini tetap ada untuk melindungi produksi yang sudah jalan sebelum
        // create_daily_usages_table diperbarui.
        Schema::table('daily_usages', function (Blueprint $table) {
            if (! Schema::hasColumn('daily_usages', 'merchant_id')) {
                $table->foreignId('merchant_id')->nullable()->after('student_id')
                    ->constrained('merchants')->nullOnDelete();
            }
        });

        // Hanya tambah constraint baru jika belum ada
        $indexes = collect(Schema::getIndexes('daily_usages'))->pluck('name');
        if (! $indexes->contains('daily_usages_student_merchant_date_unique')) {
            Schema::table('daily_usages', function (Blueprint $table) {
                $table->unique(
                    ['student_id', 'merchant_id', 'usage_date'],
                    'daily_usages_student_merchant_date_unique',
                );
            });
        }

        // Hapus unique constraint lama (student_id, usage_date) jika masih ada
        $indexes = collect(Schema::getIndexes('daily_usages'))->pluck('name');
        if ($indexes->contains('daily_usages_student_id_usage_date_unique')) {
            Schema::table('daily_usages', function (Blueprint $table) {
                $table->dropUnique('daily_usages_student_id_usage_date_unique');
            });
        }
    }

    public function down(): void
    {
        Schema::table('daily_usages', function (Blueprint $table) {
            $indexes = collect(Schema::getIndexes('daily_usages'))->pluck('name');
            if ($indexes->contains('daily_usages_student_merchant_date_unique')) {
                $table->dropUnique('daily_usages_student_merchant_date_unique');
            }
            if (Schema::hasColumn('daily_usages', 'merchant_id')) {
                $table->dropConstrainedForeignId('merchant_id');
            }
        });

        Schema::table('merchants', function (Blueprint $table) {
            if (Schema::hasColumn('merchants', 'daily_limit')) {
                $table->dropColumn('daily_limit');
            }
        });
    }
};
