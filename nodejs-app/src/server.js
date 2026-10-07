'use strict';
const { createApp } = require('./app');

const PORT = process.env.PORT || 3000;
const app = createApp();

const server = app.listen(PORT, () => {
  console.log(`nodejs-app listening on port ${PORT}`);
});

// graceful shutdown -- lets `docker stop` and Jenkins kill containers cleanly
process.on('SIGTERM', () => server.close(() => process.exit(0)));
