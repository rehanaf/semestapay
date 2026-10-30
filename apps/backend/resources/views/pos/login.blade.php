<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login Kasir — Cashless Pesantren</title>
    @fonts
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen bg-slate-100 flex items-center justify-center p-4">

    <div class="w-full max-w-sm">
        <div class="text-center mb-6">
            <h1 class="text-2xl font-bold text-slate-800">POS Kantin</h1>
            <p class="text-sm text-slate-500">Cashless Pesantren</p>
        </div>

        <form method="POST" action="{{ route('pos.login.attempt') }}"
              class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 space-y-4">
            @csrf

            @if ($errors->any())
                <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-3 py-2">
                    {{ $errors->first() }}
                </div>
            @endif

            <div>
                <label for="email" class="block text-sm font-medium text-slate-700 mb-1">Email</label>
                <input id="email" name="email" type="email" required autofocus
                       value="{{ old('email') }}"
                       class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium text-slate-700 mb-1">Password</label>
                <input id="password" name="password" type="password" required
                       class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none">
            </div>

            <button type="submit"
                    class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg py-2 text-sm transition">
                Masuk
            </button>
        </form>
    </div>

</body>
</html>