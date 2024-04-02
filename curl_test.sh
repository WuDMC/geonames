#!/bin/bash

# Выполнение запроса с помощью curl
response=$(curl -s -X POST http://localhost:4567/route -H 'Content-Type: application/json' -d '{"lat": -8.670458199999999, "lng": 115.2126293, "opts": {"size": 2, "local": true, "radius": 100, "type": "car", "rounds": 5}}')

# Проверка наличия ключа "result" в JSON ответе
if echo "$response" | jq -e '.result' > /dev/null; then
    # Извлечение значения ключа "result" и вывод в терминал
    result=$(echo "$response" | jq -r '.result')
    echo "Web service is responding OK"

    echo "Result: $result"
    # Успешное завершение с кодом 0
    exit 0
else
    # Если ключ "result" отсутствует, вывод полного ответа и кода ответа
    echo "Response: $response"
    response_code=$(echo "$response" | jq -r '.code')
    echo "BAD RESPOND"

    echo "Response code: $response_code"
    # Неудачное завершение с кодом 1
    exit 1
fi
