<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AvatarService
{
    private const MAX_BYTES = 5 * 1024 * 1024;

    /**
     * Store a base64 encoded image under public/avatars/{folder}.
     * Returns the relative path stored in the database.
     */
    public function storeBase64(?string $payload, string $folder): ?string
    {
        if ($payload === null || trim($payload) === '') {
            return null;
        }

        $payload = trim($payload);
        $extension = 'jpg';

        if (preg_match('/^data:image\/([a-zA-Z0-9+.-]+);base64,/', $payload, $matches)) {
            $extension = $this->normaliseExtension($matches[1]);
            $payload = substr($payload, strpos($payload, ',') + 1);
        }

        $binary = base64_decode($payload, true);

        if ($binary === false || $binary === '') {
            throw ValidationException::withMessages([
                'avatar' => 'Format foto tidak valid.',
            ]);
        }

        if (strlen($binary) > self::MAX_BYTES) {
            throw ValidationException::withMessages([
                'avatar' => 'Ukuran foto maksimal 5 MB.',
            ]);
        }

        $mime = $this->mimeType($binary);

        if ($mime === null || ! str_starts_with($mime, 'image/')) {
            throw ValidationException::withMessages([
                'avatar' => 'File harus berupa gambar JPG, PNG, atau WEBP.',
            ]);
        }

        $extension = $this->normaliseExtension(explode('/', $mime)[1] ?? $extension);
        $relative = 'avatars/'.$folder.'/'.Str::uuid().'.'.$extension;
        $target = public_path($relative);

        if (! is_dir(dirname($target))) {
            mkdir(dirname($target), 0755, true);
        }

        if (file_put_contents($target, $binary) === false) {
            throw ValidationException::withMessages([
                'avatar' => 'Foto gagal disimpan.',
            ]);
        }

        return $relative;
    }

    public function storeUploaded(UploadedFile $file, string $folder): string
    {
        $extension = $this->normaliseExtension($file->getClientOriginalExtension() ?: 'jpg');
        $relative = 'avatars/'.$folder.'/'.Str::uuid().'.'.$extension;
        $target = public_path($relative);

        if (! is_dir(dirname($target))) {
            mkdir(dirname($target), 0755, true);
        }

        $file->move(dirname($target), basename($target));

        return $relative;
    }

    public function delete(?string $relative): void
    {
        if ($relative !== null && $relative !== '') {
            $target = public_path($relative);

            if (is_file($target)) {
                @unlink($target);
            }
        }
    }

    private function mimeType(string $binary): ?string
    {
        if (function_exists('finfo_open')) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);

            if ($finfo !== false) {
                $mime = finfo_buffer($finfo, $binary);
                finfo_close($finfo);

                return is_string($mime) ? $mime : null;
            }
        }

        return null;
    }

    private function normaliseExtension(string $extension): string
    {
        $extension = strtolower($extension);
        $extension = $extension === 'jpeg' ? 'jpg' : $extension;

        return in_array($extension, ['jpg', 'png', 'webp', 'gif'], true)
            ? $extension
            : 'jpg';
    }
}
