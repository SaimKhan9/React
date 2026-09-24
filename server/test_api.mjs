// Quick API test
const res = await fetch('http://localhost:5000/api/execute', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ language_id: 92, source_code: 'print("Hello World")\nprint("✅ Test PASS")\nprint("❌ Test FAIL")' })
});
const d = await res.json();
console.log('HTTP Status:', res.status);
console.log('Judge0 Status:', JSON.stringify(d.status));
console.log('Stdout:', JSON.stringify(d.stdout));
console.log('Stderr:', JSON.stringify(d.stderr));
console.log('Compile output:', JSON.stringify(d.compile_output));
