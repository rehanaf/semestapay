<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 60)->nullable()->unique()->after('name');
            $table->string('avatar_path', 255)->nullable()->after('email');
            $table->foreignId('merchant_id')->nullable()->after('status')
                ->constrained('merchants')->nullOnDelete();
        });

        Schema::table('students', function (Blueprint $table) {
            $table->string('username', 60)->nullable()->unique()->after('nis');
            $table->string('email')->nullable()->unique()->after('username');
            $table->string('password_hash', 255)->nullable()->after('email');
            $table->string('avatar_path', 255)->nullable()->after('password_hash');
            $table->string('nik', 32)->nullable()->after('phone_parent');
            $table->string('gender', 20)->nullable()->after('nik');
            $table->date('birth_date')->nullable()->after('gender');
            $table->text('address')->nullable()->after('birth_date');
            $table->string('parent_name', 150)->nullable()->after('address');
            $table->string('parent_email')->nullable()->after('parent_name');
        });

        Schema::table('merchants', function (Blueprint $table) {
            $table->string('owner_name', 150)->nullable()->after('type');
            $table->string('phone', 30)->nullable()->after('owner_name');
            $table->string('email')->nullable()->after('phone');
            $table->text('address')->nullable()->after('email');
            $table->text('description')->nullable()->after('address');
            $table->string('logo_path', 255)->nullable()->after('description');
            $table->decimal('balance', 15, 2)->default(0)->after('status');
        });

        // Existing students log in with their NIS as username.
        DB::table('students')->whereNull('username')->orderBy('id')->each(function ($student) {
            DB::table('students')->where('id', $student->id)->update([
                'username' => $student->nis,
            ]);
        });

        // Existing dashboard users get a unique username derived from their email.
        DB::table('users')->whereNull('username')->orderBy('id')->each(function ($user) {
            $base = $user->email ? Str::slug(Str::before($user->email, '@')) : 'user';
            $base = $base !== '' ? $base : 'user';
            $username = $base;
            $suffix = 1;

            while (DB::table('users')->where('username', $username)->exists()) {
                $username = $base.$suffix;
                $suffix++;
            }

            DB::table('users')->where('id', $user->id)->update(['username' => $username]);
        });

        // Seed the maintained merchant balance from posted payment transactions.
        DB::table('transactions')
            ->selectRaw('merchant_id, COALESCE(SUM(amount), 0) as total')
            ->whereNotNull('merchant_id')
            ->where('type', 'payment')
            ->where('status', 'posted')
            ->groupBy('merchant_id')
            ->get()
            ->each(function ($row) {
                DB::table('merchants')->where('id', $row->merchant_id)->update([
                    'balance' => $row->total,
                ]);
            });
    }

    public function down(): void
    {
        Schema::table('merchants', function (Blueprint $table) {
            $table->dropColumn([
                'owner_name', 'phone', 'email', 'address', 'description', 'logo_path', 'balance',
            ]);
        });

        Schema::table('students', function (Blueprint $table) {
            $table->dropColumn([
                'username', 'email', 'password_hash', 'avatar_path', 'nik', 'gender',
                'birth_date', 'address', 'parent_name', 'parent_email',
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('merchant_id');
            $table->dropColumn(['username', 'avatar_path']);
        });
    }
};
