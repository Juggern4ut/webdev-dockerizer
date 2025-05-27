<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$articles = [
    [
        'id' => 1,
        'name' => 'Vintage Leather Wallet',
        'price' => 29.99,
        'inStock' => true,
        'tags' => ['leather', 'wallet', 'men'],
    ],
    [
        'id' => 2,
        'name' => 'Bluetooth Headphones',
        'price' => 89.95,
        'inStock' => false,
        'tags' => ['electronics', 'audio'],
    ],
    [
        'id' => 3,
        'name' => 'Handmade Ceramic Mug',
        'price' => 15.5,
        'inStock' => true,
        'tags' => ['home', 'kitchen', 'mug'],
    ]
];

echo json_encode($articles, JSON_PRETTY_PRINT);
