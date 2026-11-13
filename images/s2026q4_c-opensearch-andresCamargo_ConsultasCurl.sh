#!/bin/bash
# Exploración del API REST de OpenSearch con curl
# Seguridad desactivada: se usa http y no se requiere usuario/contraseña
OS="http://localhost:9200"

echo "=== 0. Verificar el clúster ==="
curl "$OS"
curl "$OS/_cluster/health?pretty"

echo "=== 1. Crear el índice con mapping ==="
curl -X PUT "$OS/ventas" -H 'Content-Type: application/json' -d '
{
  "mappings": {
    "properties": {
      "id_venta":        { "type": "integer" },
      "fecha":           { "type": "date" },
      "ciudad":          { "type": "keyword" },
      "canal":           { "type": "keyword" },
      "categoria":       { "type": "keyword" },
      "producto":        { "type": "keyword" },
      "cantidad":        { "type": "integer" },
      "precio_unitario": { "type": "long" },
      "total":           { "type": "long" },
      "metodo_pago":     { "type": "keyword" },
      "vendedor":        { "type": "keyword" },
      "calificacion":    { "type": "integer" }
    }
  }
}'

echo "=== 2. Carga masiva (Bulk API, formato NDJSON) ==="
curl -s -X POST "$OS/_bulk" -H 'Content-Type: application/x-ndjson' \
  --data-binary @ventas.ndjson | grep -o '"errors":[a-z]*'

echo "=== 3. Contar documentos (_count) ==="
curl "$OS/ventas/_count?pretty"

echo "=== 4. Obtener un solo documento (_search, size=1) ==="
curl "$OS/ventas/_search?size=1&pretty"

echo "=== 5. Estructura del índice (_mapping y _settings) ==="
curl "$OS/ventas/_mapping?pretty"
curl "$OS/ventas/_settings?pretty"

echo "=== 6. Filtro exacto con term (ciudad = Bogotá) ==="
curl -X GET "$OS/ventas/_search?pretty" -H 'Content-Type: application/json' -d '
{
  "size": 2,
  "query": { "term": { "ciudad": "Bogotá" } }
}'

echo "=== 7. Búsqueda facetada con agregaciones ==="
curl -X GET "$OS/ventas/_search?pretty" -H 'Content-Type: application/json' -d '
{
  "size": 0,
  "aggs": {
    "por_ciudad":    { "terms": { "field": "ciudad" } },
    "por_categoria": { "terms": { "field": "categoria" } }
  }
}'

echo "=== 8. Reto: filtro + agregación (ventas por canal, solo Portátiles) ==="

curl -X GET "$OS/ventas/_search?pretty" -H 'Content-Type: application/json' -d '
{
  "size": 0,
  "query": { "term": { "categoria": "Portátiles" } },
  "aggs": {
    "por_canal": { "terms": { "field": "canal" } }
  }
}'
