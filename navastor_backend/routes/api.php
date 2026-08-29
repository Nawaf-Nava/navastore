<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProductController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/products', [ProductController::class, 'index']);

// نقل مسار إضافة المنتج إلى الخارج ليتوافق مع التوكن المحلي ولإتمام الرفع بنجاح
Route::post('/products', [ProductController::class, 'store']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/favorites/toggle', [ProductController::class, 'toggleFavorite']);
    Route::get('/favorites', [ProductController::class, 'favorites']);
});