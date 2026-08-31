@extends('legal.layout')

@section('content')
    <p class="mb-6 text-sm text-slate-500">Last updated: 2026</p>

    <p>Deendoon ("the app") is a debt-collection management tool used by a single Business Owner per business account (tenant). This page explains how a Business Owner can close their Deendoon account and what happens to their data afterward.</p>

    <h2>How to Close Your Account</h2>
    <p>Account closure is a self-service action available inside the Deendoon mobile app. To close your account: open the app, go to <strong>Account</strong>, select <strong>Close Account</strong>, re-enter your password to confirm your identity, and confirm the action. There is currently no separate web form for this — it is only available in-app to the signed-in Business Owner.</p>

    <h2>What Happens When You Close Your Account</h2>
    <p>Closing your account takes effect immediately:</p>
    <ul>
        <li>All of your active login sessions and access tokens are revoked.</li>
        <li>Your user account is archived, which blocks any future login.</li>
        <li>Your business account (tenant) is suspended.</li>
        <li>The closure is recorded in Deendoon's audit log.</li>
    </ul>

    <h2>What Happens to Your Business Data</h2>
    <p>Closing your account does not immediately delete your business records. Customer records, debts, payments, collection cases, reminders, and documents remain stored, but become inaccessible once your account is archived and your business is suspended. Deendoon's general approach is to retain business data rather than permanently erase it on closure.</p>

    <h2>Data Retention</h2>
    <p>Deendoon does not currently define a fixed retention or automatic-erasure period for data after an account is closed. If you require complete removal of your business records, contact Support to discuss further options.</p>

    <h2>Further Assistance</h2>
    <p>Questions about closing your account, or requests regarding your data, can be sent through Contact Support in the app.</p>
@endsection
