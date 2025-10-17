#!/usr/bin/env node
import { Command } from "commander";
import { readFileSync } from "fs";
import path from "path";
import process from "process";
import { buildRegexFromConfig } from "../retrieve";
import { RegexConfig } from "../config/schema";

const program = new Command();

program
  .name("regex-1")
  .description("CLI utilities for regex retrieval, generation, and validation");

program
  .command("retrieve")
  .description("Generate regex candidates using a config file")
  .requiredOption("-c, --config <path>", "Path to a JSON configuration file")
  .action((options: { config: string }) => {
    const configPath = path.resolve(process.cwd(), options.config);

    try {
      const contents = readFileSync(configPath, "utf8");
      const parsed = JSON.parse(contents) as RegexConfig;
      const result = buildRegexFromConfig(parsed);
      process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Unknown error reading config";
      process.stderr.write(`Failed to load config: ${message}\n`);
      process.exitCode = 1;
    }
  });

program
  .command("generate")
  .description("Generate regex patterns from prompts")
  .action(() => {
    process.stdout.write("Not implemented in this task\n");
  });

program
  .command("validate")
  .description("Validate regex output against expectations")
  .action(() => {
    process.stdout.write("Not implemented in this task\n");
  });

program.parseAsync(process.argv).catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`${message}\n`);
  process.exit(1);
});
