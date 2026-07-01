// Simple test runner - no external test libraries needed
const http = require('http');

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✅ PASS: ${message}`);
    passed++;
  } else {
    console.log(`  ❌ FAIL: ${message}`);
    failed++;
  }
}

function makeRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path,
      method,
      headers: { 'Content-Type': 'application/json' }
    };
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  // Start the server
  const app = require('./index.js');
  await new Promise(r => setTimeout(r, 500));

  console.log('\n🧪 Running unit tests...\n');

  // Test 1: Health check
  console.log('Test: GET /health');
  const health = await makeRequest('/health');
  assert(health.status === 200, 'Health check returns 200');
  assert(health.body.status === 'ok', 'Health check status is ok');

  // Test 2: Root endpoint
  console.log('Test: GET /');
  const root = await makeRequest('/');
  assert(root.status === 200, 'Root returns 200');
  assert(root.body.message !== undefined, 'Root returns message');

  // Test 3: Get todos
  console.log('Test: GET /todos');
  const todos = await makeRequest('/todos');
  assert(todos.status === 200, 'Get todos returns 200');
  assert(Array.isArray(todos.body.todos), 'Todos is an array');

  // Test 4: Create todo
  console.log('Test: POST /todos');
  const newTodo = await makeRequest('/todos', 'POST', { title: 'Test todo' });
  assert(newTodo.status === 201, 'Create todo returns 201');
  assert(newTodo.body.title === 'Test todo', 'Created todo has correct title');

  // Test 5: Validation
  console.log('Test: POST /todos (validation)');
  const badTodo = await makeRequest('/todos', 'POST', {});
  assert(badTodo.status === 400, 'Missing title returns 400');

  // Test 6: Metrics endpoint
  console.log('Test: GET /metrics');
  const metrics = await makeRequest('/metrics');
  assert(metrics.status === 200, 'Metrics returns 200');

  console.log(`\n📊 Results: ${passed} passed, ${failed} failed\n`);

  if (failed > 0) {
    console.error('Tests failed!');
    process.exit(1);
  } else {
    console.log('All tests passed!');
    process.exit(0);
  }
}

runTests().catch(err => {
  console.error('Test error:', err.message);
  process.exit(1);
});
