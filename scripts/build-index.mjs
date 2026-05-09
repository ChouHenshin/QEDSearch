import MiniSearch from 'minisearch';
import { readFileSync, writeFileSync, readdirSync, statSync, mkdirSync } from 'fs';
import { join } from 'path';

const META_OUT = 'docs/docs-meta.json';

const SRC = 'extracted';
const OUT = 'docs/search-index.json';

const docs = [];
let id = 0;

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) walk(path);
    else if (entry.endsWith('.txt')) docs.push(path);
  }
}

walk(SRC);

const index = docs.map(path => {
  // extracted/IB/2P2/QP_2025/page-03.txt
  const parts = path.split('/');
  const part = parts[1];
  const module = parts[2];
  const paper = parts[3];
  const page = parseInt(parts[4].match(/\d+/)[0], 10);
  const text = readFileSync(path, 'utf8');
  return { id: id++, part, module, paper, page, text };
});

const mini = new MiniSearch({
  fields: ['text'],
  storeFields: ['part', 'module', 'paper', 'page', 'text'],
  searchOptions: { boost: { text: 1 }, fuzzy: 0.1, prefix: true },
});
mini.addAll(index);

mkdirSync('docs', { recursive: true });
writeFileSync(OUT, JSON.stringify(mini));

const meta = index.map(({ part, module, paper }) => ({ part, module, paper }));
writeFileSync(META_OUT, JSON.stringify(meta));

console.log(`Indexed ${index.length} pages from ${new Set(index.map(d => d.paper)).size} papers`);
console.log(`Index size: ${(statSync(OUT).size / 1024 / 1024).toFixed(2)} MB`);
console.log(`Meta size:  ${(statSync(META_OUT).size / 1024).toFixed(1)} KB`);
