<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;


Route::get('/user', function (Request $request) {
    return response()->json([
        'name' => 'John Doe',
        'email' => 'john@example.com',
    ]);
});
