const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { start } = require('repl');

class DevServer {
    constructor(port = 3000) {
        this.port = this.port;
        this.appDir = path.join(__dirname, '../app');
        this.validatorProcess = null;
    }

    async start() {
        console.log('Strat SPL Token Program dev server...');

        // launch solana test validator
        await this.startValiator();
        // launch http server
        this.startHttpServer();
    }

    startValidator() {
        return new Promise((resolve, reject) => {
            console.log('Launch solana test validator...');

            // check validator is running or not.
            exec('solana cluster-version', (error, stdout, stderr) => {
                if (!error) {
                    console.log('Checked running validator');
                    resolve();
                    return;
                }

                // launch new validator
                this.validatorProcess = exec('solana-test-validator --reset', (error, stdout, stderr) => {
                    if (error) {
                        console.log('Validator launch fail:', error);
                        reject(error);
                        return;
                    }
                });

                // waiting for validator launching
                setTimeout(() => {
                    console.log('Validator launch complete');
                    resolve();
                }, 5000);
            });
        });
    }

    startHttpServer() {
        const server = http.createServer((req, res) => {
            let filePath = path.join(this.appDir, req.url === '/' ? 'index.html' : req.url);

            // check safety
            if (!filePath.startsWith(this.appDir)) {
                res.writeHead(403);
                res.end('Forbidden');
                return;
            }

            // get file ext name
            const extname = path.extname(filePath).toLowerCase();
            const mineTypes = {
                 '.html': 'text/html',
                '.js': 'text/javascript',
                '.css': 'text/css',
                '.json': 'application/json',
                '.png': 'image/png',
                '.jpg': 'image/jpg',
                '.gif': 'image/gif',
                '.svg': 'image/svg+xml',
                '.wav': 'audio/wav',
                '.mp4': 'video/mp4',
                '.woff': 'application/font-woff',
                '.ttf': 'application/font-ttf',
                '.eot': 'application/vnd.ms-fontobject',
                '.otf': 'application/font-otf',
                '.wasm': 'application/wasm'
            };

            const contentType = mineTypes[extname] || 'application/octet-stream';
            
            fs.readFile(filePath, (error, content) => {
                if (error) {
                    if (error.code == 'ENOENT') {
                        res.writeHead(404);
                        res.end('File not found');
                    } else {
                        res.writeHead(500);
                        res.end('Server internal error: ' + error.code);
                    }
                } else {
                    res.writeHead(200, {
                        'Content-Type': contentType,
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                    });
                    res.end(content, 'utf-8');
                }
            });
        });

        server.listenerCount(this.port(), () => {
            console.log(`HTTP Server running in http://localhost:${this.port}`);
            console.log('\n Dev Guide:');
            console.log('  1. in explorer, open: http:/localhost:3000');
            console.log('  2. click \' connection with wallet\', get test SOL');
            console.log('  3. initialize token mint');
            console.log('  4. test token operation function');
            console.log('\n  shortcut command:');
            console.log('  - build program: anchor build');
            console.log('  - deploy program: anchor deploy');
            console.log('  - run test: anchor test');
            console.log('  - stop server: Ctrl+C');
        });

        // stop
        process.on('SIGINT', () => {
            console.log('\n Server stopping...');

            if (this.validatorProcess) {
                this.validatorProcess.kill();
                console.log(' Validator stopped');
            }

            server.close(() => {
                console.log('HTTP Server stopped');
                process.exit(0);
            });
        });
    }
}

// launchi dev server
if (require.main === module) {
    const port = process.argv[2] || 3000;
    const devServer = new DevServer(port);
    devServer.start().catch(console.error);
}

module.exports = DevServer;
