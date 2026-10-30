#!/usr/bin/env bash
# Checks the distributable skill kit; never runs installers or external MCPs.
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n install.sh
bun - <<'JSCI'
import {readFileSync} from 'node:fs';
const files = new Bun.Glob('{skills,skill-pipeline}/*/SKILL.md').scanSync('.');
let count=0;
for(const path of files){
  const text=readFileSync(path,'utf8');
  const match=text.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if(!match) throw new Error(`Missing skill frontmatter: ${path}`);
  const meta=Bun.YAML.parse(match[1]);
  // The public contract requires YAML metadata, not a new name/tool policy.
  // allowed-tools may be omitted or use any form the skill host supports.
  if(!meta || typeof meta!=='object' || Array.isArray(meta) || !Object.keys(meta).length) throw new Error(`Expected skill metadata mapping: ${path}`);
  count++;
}
if(!count) throw new Error('No skills validated');
const config=JSON.parse(readFileSync('.mcp.json.example','utf8'));
if(!config.mcpServers || typeof config.mcpServers!=='object') throw new Error('Invalid MCP example');
console.log(`Validated ${count} skill YAML metadata mappings, installer syntax and MCP example JSON.`);
console.log('Installer and external providers were not executed.');
JSCI
