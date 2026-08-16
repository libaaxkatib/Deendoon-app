@extends('admin.layout')

@section('content')
    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <h3 class="mb-4 text-sm font-semibold text-slate-700">New Subscription Plan</h3>

        <form method="POST" action="{{ route('admin.settings.store') }}">
            @csrf
            @include('admin.settings.partials.form')

            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Create Plan
            </button>
        </form>
    </div>
@endsection
