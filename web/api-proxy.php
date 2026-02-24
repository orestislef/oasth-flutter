<?php
// Simple proxy for OASTH telematics API to avoid browser CORS restrictions.
// Usage: /oasth/api-proxy.php?act=webGetLines&... (pass-through query string)

$base = 'https://telematics.oasth.gr/api/';
$query = $_SERVER['QUERY_STRING'] ?? '';

$target = $base . ($query ? ('?' . $query) : '');

$ch = curl_init($target);

$headers = getallheaders();
$csrfToken = $headers['X-CSRF-TOKEN'] ?? $headers['X-Csrf-Token'] ?? null;
$clientCookie = $headers['Cookie'] ?? null;

session_start();
$cookieFile = sys_get_temp_dir() . '/oasth_proxy_' . session_id() . '.cookie';

$httpHeaders = [
  'Accept: application/json, text/plain, */*',
  'Accept-Language: en-US,en;q=0.9,el;q=0.8',
  'Referer: https://telematics.oasth.gr/',
  'Origin: https://telematics.oasth.gr',
];
if ($csrfToken) {
  $httpHeaders[] = 'X-CSRF-TOKEN: ' . $csrfToken;
}

curl_setopt_array($ch, [
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_HEADER => true,
  CURLOPT_FOLLOWLOCATION => true,
  CURLOPT_TIMEOUT => 20,
  CURLOPT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  CURLOPT_HTTPHEADER => $httpHeaders,
  CURLOPT_COOKIEJAR => $cookieFile,
  CURLOPT_COOKIEFILE => $cookieFile,
]);

if ($clientCookie) {
  curl_setopt($ch, CURLOPT_COOKIE, $clientCookie);
}

$response = curl_exec($ch);
if ($response === false) {
  http_response_code(502);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode(['error' => 'proxy_failed', 'details' => curl_error($ch)]);
  curl_close($ch);
  exit;
}

$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$rawHeaders = substr($response, 0, $headerSize);
$body = substr($response, $headerSize);

$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
http_response_code($httpCode);

// Pass through content-type if present
$headers = explode("\r\n", $rawHeaders);
foreach ($headers as $header) {
  if (stripos($header, 'Content-Type:') === 0) {
    header($header);
  }
  if (stripos($header, 'Set-Cookie:') === 0) {
    header($header, false);
  }
}

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: *');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit;
}

echo $body;
curl_close($ch);
