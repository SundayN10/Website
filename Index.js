const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>My App</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
          }
          .container {
            text-align: center;
          }
          h1 {
            font-size: 3em;
            margin: 0;
          }
          p {
            font-size: 1.2em;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Server is Running!</h1>
          <p>Your app is live and working perfectly.</p>
        </div>
      </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
