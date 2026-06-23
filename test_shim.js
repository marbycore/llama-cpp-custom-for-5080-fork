const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

const TAVILY_KEY = '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';

// 1. Simular Motor Blackwell (Puerto 5050)
const mockServer = http.createServer((req, res) => {
    let body = '';
    req.on('data', d => body += d);
    req.on('end', () => {
        console.log('✅ Motor Blackwell Mock: Recibida petición aumentada.');
        fs.writeFileSync('C:/data/llama-cpp-custom/final_test_output.json', body);
        res.end('data: {"choices":[{"delta":{"content":"Respuesta de prueba"}}]}\n');
        setTimeout(() => process.exit(0), 1000);
    });
}).listen(5050);

// 2. Lanzar Shim Inteligente
console.log('🚀 Lanzando Shim Blackwell...');
const shim = spawn('node', ['ollama_shim.js', '1'], {
    env: { ...process.env, TAVILY_API_KEY: TAVILY_KEY }
});

shim.stdout.on('data', (data) => console.log('SHIM: ' + data));
shim.stderr.on('data', (data) => console.log('SHIM_ERR: ' + data));

// 3. Enviar pregunta de prueba
setTimeout(() => {
    console.log('📱 Enviando pregunta simulada desde iPhone...');
    const req = http.request({
        port: 11434,
        path: '/api/chat',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    }, (res) => {
        res.on('data', () => { });
    });
    req.write(JSON.stringify({
        messages: [{ role: 'user', content: 'Bitcoin price' }]
    }));

    req.end();
}, 5000);
