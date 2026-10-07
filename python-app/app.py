"""
Flask REST API used to learn Jenkins CI/CD, Docker and DevSecOps.

Mirrors nodejs-app on purpose: same endpoints, same behaviour, so every
Jenkins concept you learn can be practised twice -- once in Node, once in Python.
"""
import os
import time
from flask import Flask, jsonify, request

START_TIME = time.time()


def create_app():
    app = Flask(__name__)

    # in-memory store: no database, so CI stages stay fast while learning
    items = [
        {"id": 1, "name": "learn-declarative-pipeline", "done": True},
        {"id": 2, "name": "build-docker-image", "done": False},
    ]
    next_id = {"value": 3}

    @app.get("/health")
    def health():
        return jsonify(status="ok", uptimeSeconds=round(time.time() - START_TIME)), 200

    @app.get("/")
    def root():
        return jsonify(message="Jenkins Zero-to-Hero python-app", version="1.0.0"), 200

    @app.get("/api/items")
    def list_items():
        done = request.args.get("done")
        if done is None:
            result = items
        else:
            result = [i for i in items if str(i["done"]).lower() == done.lower()]
        return jsonify(count=len(result), items=result), 200

    @app.get("/api/items/<int:item_id>")
    def get_item(item_id):
        match = next((i for i in items if i["id"] == item_id), None)
        if not match:
            return jsonify(error="Item not found"), 404
        return jsonify(match), 200

    @app.post("/api/items")
    def create_item():
        payload = request.get_json(silent=True) or {}
        name = payload.get("name")
        if not isinstance(name, str) or len(name.strip()) < 2:
            return jsonify(error="`name` is required (min 2 characters)"), 400
        item = {"id": next_id["value"], "name": name.strip(), "done": False}
        next_id["value"] += 1
        items.append(item)
        return jsonify(item), 201

    @app.delete("/api/items/<int:item_id>")
    def delete_item(item_id):
        for index, item in enumerate(items):
            if item["id"] == item_id:
                return jsonify(items.pop(index)), 200
        return jsonify(error="Item not found"), 404

    @app.errorhandler(404)
    def not_found(_err):
        return jsonify(error="Not Found", path=request.path), 404

    return app


app = create_app()


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
