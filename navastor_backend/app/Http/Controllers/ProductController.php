<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\Favorite;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index()
    {
        return response()->json(Product::latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric',
            'category' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
        ]);

        $imageUrl = null;

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('products', 'public');
            $imageUrl = asset('storage/' . $path);
        }

        $product = Product::create([
            'name' => $validated['name'],
            'description' => $validated['description'] ?? null,
            'price' => $validated['price'],
            'category' => $validated['category'] ?? 'الكترونيات',
            'image' => $imageUrl,
            'publisher' => $request->user() ? $request->user()->name : 'بائع معتمد',
            'rating' => 5.0,
            'tag' => 'جديد',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم إضافة المنتج بنجاح', 
            'product' => $product
        ], 201);
    }

    public function toggleFavorite(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id'
        ]);

        $userId = $request->user()->id;
        $productId = $request->product_id;

        $favorite = Favorite::where('user_id', $userId)->where('product_id', $productId)->first();

        if ($favorite) {
            $favorite->delete();
            return response()->json(['message' => 'تمت الإزالة من المفضلة']);
        }

        Favorite::create([
            'user_id' => $userId,
            'product_id' => $productId
        ]);

        return response()->json(['message' => 'تمت الإضافة إلى المفضلة']);
    }

    public function favorites(Request $request)
    {
        $favorites = $request->user()->favorites()->with('product')->get();
        return response()->json($favorites);
    }
}