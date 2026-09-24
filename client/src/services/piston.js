const SERVER_URL = import.meta.env.VITE_SERVER_URL || "http://localhost:5000";

// UTF-8 safe Base64 encoder for browser
function toBase64(str) {
  try {
    return btoa(unescape(encodeURIComponent(str)));
  } catch (e) {
    return btoa(str);
  }
}

// UTF-8 safe Base64 decoder for browser
function fromBase64(str) {
  if (!str) return null;
  try {
    return decodeURIComponent(escape(atob(str)));
  } catch (e) {
    try {
      return atob(str);
    } catch {
      return str;
    }
  }
}

export async function executeCode(languageObj, code, stdin = "") {
  const payload = {
    language_id: languageObj.judge0Id,
    source_code: code,
    stdin: stdin || ""
  };

  // Try server proxy first (handles base64, CORS, and connection pooling)
  try {
    const proxyRes = await fetch(`${SERVER_URL}/api/execute`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    if (proxyRes.ok) {
      return await proxyRes.json();
    }
  } catch (err) {
    console.warn("Proxy execution failed, falling back to direct Judge0 API:", err.message);
  }

  // Fallback direct call to Judge0 CE with base64_encoded=true
  const base64Source = toBase64(code);
  const base64Stdin = stdin ? toBase64(stdin) : "";

  const directRes = await fetch("https://ce.judge0.com/submissions?base64_encoded=true&wait=true", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      language_id: languageObj.judge0Id,
      source_code: base64Source,
      stdin: base64Stdin,
      redirect_stderr_to_stdout: false
    })
  });

  if (!directRes.ok) {
    const errText = await directRes.text();
    throw new Error(`Judge0 API returned status: ${directRes.status} (${errText})`);
  }

  const rawData = await directRes.json();

  return {
    ...rawData,
    stdout: fromBase64(rawData.stdout),
    stderr: fromBase64(rawData.stderr),
    compile_output: fromBase64(rawData.compile_output),
    message: fromBase64(rawData.message)
  };
}
