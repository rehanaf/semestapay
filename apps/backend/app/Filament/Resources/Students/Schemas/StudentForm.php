<?php

namespace App\Filament\Resources\Students\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class StudentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                // ── Data Akun ─────────────────────────────────────────────
                TextInput::make('nis')
                    ->label('NIS')
                    ->required()
                    ->unique(ignoreRecord: true),

                TextInput::make('username')
                    ->maxLength(60)
                    ->unique(ignoreRecord: true)
                    ->helperText('Otomatis memakai NIS bila dikosongkan.'),

                TextInput::make('name')
                    ->label('Nama Lengkap')
                    ->required(),

                TextInput::make('email')
                    ->email()
                    ->unique(ignoreRecord: true),

                TextInput::make('phone')
                    ->label('Nomor Telepon')
                    ->tel(),

                TextInput::make('nik')
                    ->label('NIK')
                    ->maxLength(32),

                Select::make('gender')
                    ->label('Jenis Kelamin')
                    ->options([
                        'male' => 'Laki-laki',
                        'female' => 'Perempuan',
                    ]),

                TextInput::make('birth_place')
                    ->label('Tempat Lahir'),

                DatePicker::make('birth_date')
                    ->label('Tanggal Lahir'),

                Select::make('religion')
                    ->label('Agama')
                    ->options([
                        'islam' => 'Islam',
                        'kristen' => 'Kristen',
                        'katolik' => 'Katolik',
                        'hindu' => 'Hindu',
                        'buddha' => 'Buddha',
                        'konghucu' => 'Konghucu',
                        'lainnya' => 'Lainnya',
                    ]),

                Select::make('marital_status')
                    ->label('Status Pernikahan')
                    ->options([
                        'single' => 'Belum Menikah',
                        'married' => 'Menikah',
                        'divorce' => 'Cerai',
                    ])
                    ->default('single'),

                Textarea::make('address')
                    ->label('Alamat')
                    ->columnSpanFull(),

                TextInput::make('avatar_path')
                    ->label('Gambar / Path Foto Profil')
                    ->maxLength(255),

                // ── Data Orang Tua / Wali ──────────────────────────────────
                TextInput::make('parent_name')
                    ->label('Nama Orang Tua / Wali'),

                TextInput::make('parent_email')
                    ->label('Email Orang Tua')
                    ->email(),

                TextInput::make('phone_parent')
                    ->label('Nomor Telepon Orang Tua')
                    ->tel(),

                // ── Kelas & Status ─────────────────────────────────────────
                Select::make('class_id')
                    ->label('Kelas')
                    ->relationship('klass', 'name')
                    ->searchable()
                    ->preload(),

                Select::make('status')
                    ->label('Status Santri')
                    ->required()
                    ->options([
                        'active' => 'Aktif',
                        'inactive' => 'Nonaktif',
                    ])
                    ->default('active'),

                // ── Kartu ─────────────────────────────────────────────────
                TextInput::make('card_uid')
                    ->label('UID Kartu')
                    ->unique(ignoreRecord: true),

                Select::make('card_status')
                    ->label('Status Kartu')
                    ->options([
                        'active' => 'Aktif',
                        'blocked' => 'Diblokir',
                        'lost' => 'Hilang',
                    ])
                    ->default('active'),

                DateTimePicker::make('card_assigned_at')
                    ->label('Tanggal Kartu Ditetapkan'),

                // ── Dompet ────────────────────────────────────────────────
                TextInput::make('balance')
                    ->label('Saldo')
                    ->numeric()
                    ->default(0),

                Select::make('wallet_status')
                    ->label('Status Dompet')
                    ->required()
                    ->options([
                        'active' => 'Aktif',
                        'frozen' => 'Dibekukan',
                        'closed' => 'Ditutup',
                    ])
                    ->default('active'),

                TextInput::make('daily_limit')
                    ->label('Limit Harian')
                    ->numeric()
                    ->default(0),

                DateTimePicker::make('balance_updated_at')
                    ->label('Saldo Diperbarui'),
            ]);
    }
}
