const fs = require("node:fs");
const path = require("node:path");
const Ajv2020 = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

const root = path.resolve(__dirname, "..");

const schemaPath = path.join(
  root,
  "config",
  "takeover-audit",
  "schema",
  "process.schema.json"
);

const dataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "process.json"
);

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    console.error(`Unable to read valid JSON from ${filePath}`);
    console.error(error.message);
    process.exit(1);
  }
}

const schema = readJson(schemaPath);
const data = readJson(dataPath);

const ajv = new Ajv2020({
  allErrors: true,
  strict: true,
  strictRequired: false
});

addFormats(ajv);

const validate = ajv.compile(schema);
const valid = validate(data);

if (!valid) {
  console.error("Takeover Audit process configuration is invalid:");

  for (const error of validate.errors ?? []) {
    console.error(
      `- ${error.instancePath || "/"}: ${error.message}`
    );
  }

  process.exit(1);
}

console.log("Takeover Audit process configuration is valid.");
