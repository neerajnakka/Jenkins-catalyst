'use strict';
/**
 * Jest + Supertest suite.
 * Jenkins publishes reports/junit.xml (jest-junit) + coverage/ (lcov + cobertura).
 */
const request = require('supertest');
const { createApp } = require('../src/app');

const app = createApp();

describe('health & root', () => {
  test('GET /health returns 200 and status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET / returns the service banner', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('version');
  });
});

describe('items API', () => {
  test('GET /api/items lists seeded items', async () => {
    const res = await request(app).get('/api/items');
    expect(res.status).toBe(200);
    expect(res.body.items.length).toBeGreaterThan(0);
  });

  test('POST /api/items creates an item (201)', async () => {
    const res = await request(app).post('/api/items').send({ name: 'push-to-dockerhub' });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ name: 'push-to-dockerhub', done: false });
  });

  test('POST /api/items rejects an invalid body (400)', async () => {
    const res = await request(app).post('/api/items').send({ name: 'x' });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  test('GET /api/items/:id returns 404 for unknown id', async () => {
    const res = await request(app).get('/api/items/999999');
    expect(res.status).toBe(404);
  });

  test('DELETE /api/items/:id removes the item', async () => {
    const created = await request(app).post('/api/items').send({ name: 'temp-item' });
    const res = await request(app).delete(`/api/items/${created.body.id}`);
    expect(res.status).toBe(200);
  });
});

describe('routing', () => {
  test('unknown path returns JSON 404', async () => {
    const res = await request(app).get('/does-not-exist');
    expect(res.status).toBe(404);
    expect(res.headers['content-type']).toMatch(/json/);
  });
});
