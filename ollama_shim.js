const http = require('http');

const TARGET_PORT = 5050;
const PROXY_PORT = 11434;

console.log(`[Elite] Traductor de Flujo Directo activo (${PROXY_PORT} -> ${TARGET_PORT})`);

const server = http.createServer((req, res) => {
    let url = req.url;
    let targetPath = url;

    // Handshake de Descubrimiento
    if (url === '/api/tags' || url === '/api/models' || url === '/v1/models') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            models: [{
                name: "Blackwell-RTX5080",
                model: "Blackwell-RTX5080",
                details: { family: "llama", format: "gguf" }
            }]
        }));
        return;
    }

    // Traduccion de Rutas
    if (url === '/api/chat') targetPath = '/v1/chat/completions';
    if (url === '/api/generate') targetPath = '/v1/completions';

    console.log(`[Proxy] ${req.method} ${url} -> ${targetPath}`);

    const proxyReq = http.request({
        host: '127.0.0.1',
        port: TARGET_PORT,
        path: targetPath,
        method: req.method,
        headers: { ...req.headers, host: '127.0.0.1:' + TARGET_PORT }
    }, (proxyRes) => {
        // Si no es un flujo de chat, pasamos la respuesta tal cual
        if (url !== '/api/chat' && url !== '/api/generate') {
            res.writeHead(proxyRes.statusCode, proxyRes.headers);
            proxyRes.pipe(res);
            return;
        }

        // --- TRADUCTOR DE STREAMING (SSE to NDJSON) ---
        res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });

        proxyRes.on('data', (chunk) => {
            const lines = chunk.toString().split('\n');
            for (let line of lines) {
                if (line.startsWith('data: ')) {
                    const dataStr = line.slice(6).trim();
                    if (dataStr === '[DONE]') continue;
                    try {
                        const json = JSON.parse(dataStr);
                        const content = json.choices[0].delta.content || "";
                        if (content) {
                            res.write(JSON.stringify({
                                model: "Blackwell-RTX5080",
                                message: { role: "assistant", content: content },
                                done: false
                            }) + '\n');
                        }
                    } catch (e) { }
                }
            }
        });

        proxyRes.on('end', () => {
            res.write(JSON.stringify({ done: true }) + '\n');
            res.end();
        });
    });

    req.pipe(proxyReq);
    proxyReq.on('error', () => {
        res.writeHead(502);
        res.end(JSON.stringify({ error: "Motor Blackwell no disponible" }));
    });
});

server.listen(PROXY_PORT, '0.0.0.0');
