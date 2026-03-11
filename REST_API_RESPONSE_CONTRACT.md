# REST API Auth Error Contract

This contract defines the API Gateway REST(v1) gateway-response envelope for auth failures.

## Target Responses

### 401 Unauthorized
```json
{
  "success": false,
  "message": "유효하지 않거나 만료된 토큰입니다.",
  "data": null
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "권한이 없습니다.",
  "data": null
}
```

## Notes
- Envelope follows monolith `common_response` shape.
- REST custom authorizer returns `Unauthorized` on token failure so auth rejection is emitted as 401.
- `403` is reserved for explicit deny/permission-failure cases.
