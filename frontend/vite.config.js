import { defineConfig } from 'vite';

const mockServer = {
  configureServer(server) {
    let counter = 0;

    server.middlewares.use('/api/counter', (req, res, next) => {
      res.setHeader('Content-Type', 'application/json');

      if (req.method === 'GET') {
        res.end(JSON.stringify({ value: counter }));
      } else if (req.method === 'POST') {
        counter++;
        res.end(JSON.stringify({ value: counter }));
      } else {
        next();
      }
    });
  },
};

export default defineConfig({
  plugins: [mockServer],
});
