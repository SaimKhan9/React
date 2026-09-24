import { LANGUAGES } from '../client/src/constants/languages.js';

async function testBase64() {
  const py = LANGUAGES.find(l => l.id === 'python');
  const js = LANGUAGES.find(l => l.id === 'javascript');

  for (const lang of [py, js]) {
    console.log(`Testing Base64 for ${lang.name}...`);
    const encodedSource = Buffer.from(lang.sample, 'utf8').toString('base64');
    
    const res = await fetch('https://ce.judge0.com/submissions?base64_encoded=true&wait=true', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        language_id: lang.judge0Id,
        source_code: encodedSource
      })
    });

    if (!res.ok) {
      console.error(`FAILED: ${res.status}`, await res.text());
    } else {
      const data = await res.json();
      const stdout = data.stdout ? Buffer.from(data.stdout, 'base64').toString('utf8') : null;
      const stderr = data.stderr ? Buffer.from(data.stderr, 'base64').toString('utf8') : null;
      console.log(`SUCCESS ${lang.name}! Status:`, data.status?.description);
      console.log('Decoded stdout:\n', stdout);
      if (stderr) console.log('Decoded stderr:\n', stderr);
    }
  }
}

testBase64();

