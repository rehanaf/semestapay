<div class="min-h-screen flex flex-col"
     x-data
     @keydown.window="
        if ($event.key === 'F5') { $event.preventDefault(); $refs.scan?.focus(); }
        else if ($event.key === 'F6') { $event.preventDefault(); $wire.pay(); }
        else if ($event.key === 'F7') { $event.preventDefault(); $wire.closeStudentModal().then(() => $nextTick(() => $refs.manual?.focus())); }
     ">

    <header class="bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between">
        <div>
            <h1 class="text-lg font-bold text-slate-800">POS Kasir</h1>
            <p class="text-sm text-slate-500">
                @if ($this->outlet)
                    {{ $this->outlet->merchant->name }} — {{ $this->outlet->name }}
                @else
                    Belum terkait outlet
                @endif
            </p>
        </div>
        <div class="flex items-center gap-3">
            <span class="inline-flex items-center gap-2 text-sm font-medium rounded-full px-3 py-1
                {{ $this->shiftOpen ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700' }}">
                <span class="w-2 h-2 rounded-full {{ $this->shiftOpen ? 'bg-emerald-500' : 'bg-amber-500' }}"></span>
                {{ $this->shiftOpen ? 'Shift terbuka' : 'Shift belum dibuka' }}
            </span>

            @if ($this->outlet && ! $this->shiftOpen)
                <button wire:click="openShift"
                        class="bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg px-3 py-1.5">
                    Buka Shift
                </button>
            @elseif ($this->outlet && $this->shiftOpen)
                <button wire:click="closeShift"
                        class="bg-white border border-red-300 text-red-600 hover:bg-red-50 text-sm font-medium rounded-lg px-3 py-1.5">
                    Tutup Shift
                </button>
            @endif

            <form method="POST" action="{{ route('pos.logout') }}">
                @csrf
                <button type="submit"
                        class="text-slate-500 hover:text-slate-700 text-sm font-medium rounded-lg px-3 py-1.5 border border-slate-200">
                    Keluar
                </button>
            </form>
        </div>
    </header>

    <main class="flex-1 p-4 grid grid-cols-12 gap-4 max-w-7xl w-full mx-auto">

        {{-- Panel kiri: scan + data santri --}}
        <section class="col-span-3 space-y-4">
            <div class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                <label class="block text-sm font-semibold text-slate-700 mb-2">Scan Kartu
                    <span class="text-xs font-normal text-slate-400">(F5)</span>
                </label>
                <input type="text" autofocus autocomplete="off" x-ref="scan"
                       wire:model.live.debounce.400ms="cardUid"
                       wire:keydown.enter="scanCard"
                       placeholder="Tempel kartu RFID..."
                       class="w-full rounded-lg border border-slate-300 px-3 py-3 text-lg tracking-widest uppercase text-center focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none">
                <p class="mt-2 text-xs text-slate-400">
                    Selesaikan nominal dulu, lalu tempel kartu.
                </p>
            </div>

            @if ($this->notice)
                <div class="bg-blue-50 border border-blue-200 text-blue-700 text-sm rounded-xl px-4 py-3">
                    {{ $this->notice }}
                </div>
            @endif

            @if ($this->error && ! $this->showStudentModal)
                <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                    {{ $this->error }}
                </div>
            @endif

            @if (! $this->student)
                <div class="bg-white border border-dashed border-slate-300 text-slate-400 text-sm rounded-xl px-4 py-6 text-center">
                    Selesaikan jumlah harga terlebih dahulu, lalu tempel kartu santri di reader.
                    <br>
                    Modal <span class="font-semibold text-slate-500">Profil Siswa</span> akan muncul untuk konfirmasi &amp; PIN.
                </div>
            @endif
        </section>

        {{-- Panel tengah: item & nominal --}}
        <section class="col-span-6 space-y-4">
            <div class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                <div class="flex items-center justify-between mb-3">
                    <h2 class="font-semibold text-slate-700">Menu</h2>
                    @if ($this->cart !== [])
                        <button wire:click="clearCart" class="text-sm text-slate-500 hover:text-red-600">
                            Kosongkan keranjang
                        </button>
                    @endif
                </div>

                @if ($this->items->isEmpty())
                    <p class="text-sm text-slate-400">Belum ada item untuk merchant ini.</p>
                @else
                    <div class="grid grid-cols-3 gap-2">
                        @foreach ($this->items as $item)
                            <button wire:click="addItem({{ $item->id }})" type="button"
                                    class="rounded-lg border border-slate-200 hover:border-blue-400 hover:bg-blue-50 px-3 py-2 text-left transition">
                                <p class="text-sm font-medium text-slate-700">{{ $item->name }}</p>
                                <p class="text-sm font-semibold text-blue-600">Rp {{ number_format((float) $item->price, 0, ',', '.') }}</p>
                            </button>
                        @endforeach
                    </div>
                @endif
            </div>

            <div class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                <label class="block text-sm font-semibold text-slate-700 mb-2">Nominal Manual (opsional)
                    <span class="text-xs font-normal text-slate-400">(F7)</span>
                </label>
                <div class="flex gap-2">
                    <input type="number" min="0" step="500" x-ref="manual" wire:model.live.debounce.300ms="manualAmount"
                           class="w-full rounded-lg border border-slate-300 px-3 py-2 text-right text-lg outline-none focus:ring-2 focus:ring-blue-500">
                    <button wire:click="addManual(5000)" type="button"
                            class="rounded-lg border border-slate-300 px-3 hover:bg-slate-50 text-sm">
                        +5.000
                    </button>
                </div>
            </div>
        </section>

        {{-- Panel kanan: keranjang, total, bayar --}}
        <section class="col-span-3 space-y-4">
            <div class="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                <h2 class="font-semibold text-slate-700 mb-3">Keranjang</h2>

                @if ($this->cartLines->isEmpty())
                    <p class="text-sm text-slate-400 mb-3">Belum ada item.</p>
                @else
                    <ul class="space-y-2 mb-4">
                        @foreach ($this->cartLines as $row)
                            <li class="flex items-center justify-between text-sm">
                                <div>
                                    <p class="font-medium text-slate-700">{{ $row['item']->name }}</p>
                                    <p class="text-slate-400 text-xs">Rp {{ number_format((float) $row['item']->price, 0, ',', '.') }}</p>
                                </div>
                                <div class="flex items-center gap-2">
                                    <button wire:click="decrementItem({{ $row['item']->id }})" type="button"
                                            class="w-6 h-6 rounded border border-slate-300 hover:bg-slate-50">−</button>
                                    <span class="w-6 text-center font-semibold">{{ $row['quantity'] }}</span>
                                    <button wire:click="incrementItem({{ $row['item']->id }})" type="button"
                                            class="w-6 h-6 rounded border border-slate-300 hover:bg-slate-50">+</button>
                                </div>
                            </li>
                        @endforeach
                    </ul>
                @endif

                <div class="border-t border-slate-200 pt-3 flex items-center justify-between">
                    <span class="font-medium text-slate-600">Total</span>
                    <span class="text-2xl font-extrabold text-slate-800">
                        Rp {{ number_format($this->total(), 0, ',', '.') }}
                    </span>
                </div>
            </div>

            <button wire:click="pay" wire:loading.attr="disabled"
                    type="button"
                    class="w-full bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold text-lg rounded-xl py-4 shadow transition">
                Bayar
                <span class="text-sm font-normal opacity-80">(F6)</span>
            </button>

            <div wire:loading wire:target="pay" class="text-center text-sm text-slate-500">
                Memproses...
            </div>

            @if ($this->lastTransactionId)
                <div class="bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm rounded-xl px-4 py-3">
                    Berhasil! Transaksi <span class="font-mono">#{{ substr($this->lastTransactionId, 0, 8) }}</span>
                    — saldo akhir Rp {{ number_format((float) $this->lastBalanceAfter, 0, ',', '.') }}
                </div>
            @endif

            @if ($this->error && ! $this->showStudentModal)
                <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                    {{ $this->error }}
                </div>
            @endif
        </section>

    </main>

    @if ($this->showStudentModal && $this->student)
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4"
             x-data
             @keydown.escape.window="$wire.closeStudentModal()">
            <div class="w-full max-w-md bg-white rounded-xl shadow-xl border border-slate-200 p-6 space-y-4"
                 x-init="$nextTick(() => ($refs.pin ?? $refs.confirm)?.focus())">

                <div class="flex items-start justify-between">
                    <div>
                        <p class="text-xs uppercase tracking-wide text-slate-400">Profil Siswa</p>
                        <p class="text-xl font-bold text-slate-800">{{ $this->student->name }}</p>
                        <p class="text-sm text-slate-500">
                            {{ $this->student->nis }} · {{ $this->student->klass?->name ?? '-' }}
                        </p>
                    </div>
                    <button type="button" wire:click="closeStudentModal"
                            class="text-slate-400 hover:text-slate-600 text-xl leading-none">&times;</button>
                </div>

                <div class="grid grid-cols-2 gap-3 text-sm">
                    <div class="bg-emerald-50 border border-emerald-200 rounded-lg px-3 py-2">
                        <p class="text-emerald-700/70">Saldo</p>
                        <p class="font-semibold text-emerald-700">
                            Rp {{ number_format((float) $this->student->balance, 0, ',', '.') }}
                        </p>
                    </div>
                    <div class="bg-slate-50 border border-slate-200 rounded-lg px-3 py-2">
                        <p class="text-slate-400">Pemakaian Hari Ini</p>
                        <p class="font-semibold text-slate-700">
                            Rp {{ number_format($this->dailyUsed, 0, ',', '.') }}
                            <span class="text-slate-400">/ {{ number_format((float) $this->student->daily_limit, 0, ',', '.') }}</span>
                        </p>
                    </div>
                </div>

                <div class="flex items-center justify-between border-t border-b border-slate-200 py-3">
                    <span class="font-medium text-slate-600">Total Bayar</span>
                    <span class="text-2xl font-extrabold text-slate-800">
                        Rp {{ number_format($this->total(), 0, ',', '.') }}
                    </span>
                </div>

                @if ($this->student->hasPin())
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-1">PIN Santri</label>
                        <input type="password" inputmode="numeric" maxlength="6" x-ref="pin"
                               wire:model="pin" wire:keydown.enter="pay"
                               class="w-full rounded-lg border border-slate-300 px-3 py-2 text-center text-lg tracking-widest outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                @endif

                @if ($this->error)
                    <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-3 py-2">
                        {{ $this->error }}
                    </div>
                @endif

                <div class="flex gap-3">
                    <button type="button" wire:click="closeStudentModal"
                            class="w-1/3 rounded-lg border border-slate-300 text-slate-600 hover:bg-slate-50 py-3 font-medium">
                        Batal
                    </button>
                    <button type="button" wire:click="pay" wire:loading.attr="disabled" x-ref="confirm"
                            class="w-2/3 rounded-lg bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold py-3 shadow transition">
                        Konfirmasi <span class="text-sm font-normal opacity-80">(F6)</span>
                    </button>
                </div>
            </div>
        </div>
    @endif

    <footer class="px-4 py-3 text-center text-xs text-slate-400">
        Cashless Pesantren · {{ auth()->user()->name }} ·
        <span class="font-mono">F5</span> Scan
        <span class="font-mono">F6</span> Konfirmasi
        <span class="font-mono">F7</span> Nominal
    </footer>

</div>