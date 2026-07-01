const express = require('express');
const app = express();
app.use(express.json());

// Track simple metrics in memory
let requestCount = 0;
let errorCount = 0;
const startTime = Date.now();

// Middleware to count requests
app.use((req, res, next) => {
  requestCount++;
  next();
});

// Health check endpoint (used by ALB)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: Math.floor((Date.now() - startTime) / 1000) });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: '8Byte API is running!',
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// Simple CRUD - in-memory todos (no DB needed for demo)
let todos = [
  { id: 1, title: 'Set up Terraform', done: true },
  { id: 2, title: 'Configure CI/CD', done: true },
  { id: 3, title: 'Add monitoring', done: false }
];
let nextId = 4;

app.get('/todos', (req, res) => {
  res.json({ todos, total: todos.length });
});

app.post('/todos', (req, res) => {
  const { title } = req.body;
  if (!title) {
    errorCount++;
    return res.status(400).json({ error: 'Title is required' });
  }
  const todo = { id: nextId++, title, done: false };
  todos.push(todo);
  res.status(201).json(todo);
});

app.put('/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).json({ error: 'Not found' });
  todo.done = !todo.done;
  res.json(todo);
});

app.delete('/todos/:id', (req, res) => {
  const index = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (index === -1) return res.status(404).json({ error: 'Not found' });
  todos.splice(index, 1);
  res.json({ message: 'Deleted' });
});

// Prometheus-style metrics endpoint
app.get('/metrics', (req, res) => {
  const uptime = Math.floor((Date.now() - startTime) / 1000);
  const metrics = `# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total ${requestCount}

# HELP http_errors_total Total HTTP errors
# TYPE http_errors_total counter
http_errors_total ${errorCount}

# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds ${uptime}

# HELP todos_total Total number of todos
# TYPE todos_total gauge
todos_total ${todos.length}
`;
  res.set('Content-Type', 'text/plain');
  res.send(metrics);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
