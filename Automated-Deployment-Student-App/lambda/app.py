"""Small CRUD API for a student directory (API Gateway HTTP API payload v2)."""
import json
import os
import uuid
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Attr

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
origin = os.environ.get("ALLOWED_ORIGIN", "*")

class DecimalEncoder(json.JSONEncoder):
    def default(self, value):
        if isinstance(value, Decimal):
            return int(value) if value % 1 == 0 else float(value)
        return super().default(value)

def response(status, body=None):
    return {"statusCode": status, "headers": {"content-type": "application/json", "access-control-allow-origin": origin}, "body": "" if body is None else json.dumps(body, cls=DecimalEncoder)}

def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/")
    student_id = (event.get("pathParameters") or {}).get("id")
    try:
        if method == "GET" and not student_id:
            items = table.scan().get("Items", [])
            return response(200, sorted(items, key=lambda s: s.get("name", "").lower()))
        if method == "GET" and student_id:
            result = table.get_item(Key={"student_id": student_id}).get("Item")
            return response(200, result) if result else response(404, {"error": "Student not found"})
        if method in ("POST", "PUT"):
            data = json.loads(event.get("body") or "{}")
            name = str(data.get("name", "")).strip()
            email = str(data.get("email", "")).strip()
            course = str(data.get("course", "")).strip()
            if not name or not email or not course:
                return response(400, {"error": "name, email, and course are required"})
            if method == "POST":
                item = {"student_id": str(uuid.uuid4()), "name": name, "email": email, "course": course}
                table.put_item(Item=item)
                return response(201, item)
            item = {"student_id": student_id, "name": name, "email": email, "course": course}
            table.put_item(Item=item)
            return response(200, item)
        if method == "DELETE" and student_id:
            table.delete_item(Key={"student_id": student_id})
            return response(200, {"deleted": student_id})
        return response(404, {"error": f"No route for {method} {path}"})
    except json.JSONDecodeError:
        return response(400, {"error": "Request body must be valid JSON"})
    except Exception as exc:
        print(f"Request failed: {exc}")
        return response(500, {"error": "Internal server error"})
