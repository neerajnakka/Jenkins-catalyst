'use strict';
/**
 * Express application factory.
 * Kept separate from server.js so tests can import the app
 * WITHOUT binding a port (that is the #1 rule of testable Node services).
 */
const express = require('express');
const itemsRouter = require('./routes/items');

function createApp() {
  const app = express();

  app.use(express.json());

  // ---- health & readiness: used by the Docker HEALTHCHECK and by Jenkins smoke tests
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', uptimeSeconds: Math.round(process.uptime()) });
  });

  app.get('/', (req, res) => {
    res.status(200).json({ message: 'Jenkins Zero-to-Hero nodejs-app', version: '1.0.0' });
  });

  app.use('/api/items', itemsRouter);

  // ---- unknown route -> clean JSON 404 (never an HTML stack page)
  app.use((req, res) => res.status(404).json({ error: 'Not Found', path: req.path }));

  // ---- central error handler (4-arg signature is how Express recognises it)
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    const status = err.status || 500;
    res.status(status).json({ error: err.message || 'Internal Server Error' });
  });

  return app;
}

module.exports = { createApp };
