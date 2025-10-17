# regex-1

Internal tooling for exploring regex retrieval strategies. This package provides a TypeScript CLI that can read configuration files and produce regex candidates.

## Getting started

```bash
npm install
```

## Available scripts

- `npm run dev` – run the CLI entry point with ts-node for local development
- `npm run build` – compile TypeScript sources to `dist/`
- `npm run test` – execute the Vitest suite
- `npm run lint` – lint the project with ESLint
- `npm run typecheck` – run the TypeScript compiler in type-check mode

## Using the CLI

After building the project, you can run the retrieval command:

```bash
npm run build
node dist/cli.js retrieve --config ./path/to/config.json
```

During development you can use the TypeScript entry point directly:

```bash
npm run dev -- retrieve --config ./path/to/config.json
```

The command prints the generated regex candidates (primary and variants) as formatted JSON to standard output.
