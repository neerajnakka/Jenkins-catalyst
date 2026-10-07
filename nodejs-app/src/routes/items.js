'use strict';
/**
 * Tiny in-memory CRUD API.
 * No database on purpose: every Jenkins stage (build, test, scan, docker, deploy)
 * must run in seconds so you can iterate while learning.
 */
const express = require('express');
const router = express.Router();

let items = [
  { id: 1, name: 'learn-declarative-pipeline', done: true },
  { id: 2, name: 'build-docker-image', done: false }
];
let nextId = 3;

// GET /api/items  -> list (optional ?done=true filter)
router.get('/', (req, res) => {
  const { done } = req.query;
  const result = done === undefined ? items : items.filter(i => String(i.done) === done);
  res.status(200).json({ count: result.length, items: result });
});

// GET /api/items/:id -> one item or 404
router.get('/:id', (req, res, next) => {
  const item = items.find(i => i.id === Number(req.params.id));
  if (!item) return next(Object.assign(new Error('Item not found'), { status: 404 }));
  res.status(200).json(item);
});

// POST /api/items -> create (400 on invalid body)
router.post('/', (req, res, next) => {
  const { name } = req.body || {};
  if (typeof name !== 'string' || name.trim().length < 2) {
    return next(Object.assign(new Error('`name` is required (min 2 characters)'), { status: 400 }));
  }
  const item = { id: nextId++, name: name.trim(), done: false };
  items.push(item);
  res.status(201).json(item);
});

// DELETE /api/items/:id -> remove or 404
router.delete('/:id', (req, res, next) => {
  const idx = items.findIndex(i => i.id === Number(req.params.id));
  if (idx === -1) return next(Object.assign(new Error('Item not found'), { status: 404 }));
  const [removed] = items.splice(idx, 1);
  res.status(200).json(removed);
});

// used by tests to get a clean state
router._reset = () => { items = []; nextId = 1; };

module.exports = router;
