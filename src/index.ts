import express, { Request, Response } from 'express';
import { execSync } from 'child_process';
import { writeFileSync, unlinkSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';

const app = express();
app.use(express.json());

const TEMP_DIR = '/tmp/sandbox';

interface ExecuteRequest {
  language: 'python' | 'nodejs';
  code: string;
}

app.post('/execute', (req: Request, res: Response) => {
  const { language, code } = req.body as ExecuteRequest;

  if (!language || !code) {
    return res.status(400).json({ error: 'language and code are required' });
  }

  const id = uuidv4();
  const ext = language === 'python' ? 'py' : 'js';
  const filename = `${id}.${ext}`;
  const filepath = path.join(TEMP_DIR, filename);

  try {
    // Write code to temp file
    writeFileSync(filepath, code);

    const image = language === 'python' ? 'sandbox-python' : 'sandbox-nodejs';
    const cmd = language === 'python'
      ? `docker run --rm --memory=256m --cpus=0.5 -v ${filepath}:/code/solution.${ext}:ro ${image}`
      : `docker run --rm --memory=256m --cpus=0.5 -v ${filepath}:/code/solution.${ext}:ro ${image}`;

    const output = execSync(cmd, { timeout: 10000 }).toString();
    unlinkSync(filepath);

    return res.json({ success: true, output });
  } catch (err: any) {
    try { unlinkSync(filepath); } catch {}
    return res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(3000, () => console.log('API running on port 3000'));