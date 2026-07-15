const fs = require("node:fs");
const path = require("node:path");
const Ajv2020 = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

const root = path.resolve(__dirname, "..");

function readJson(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");
    return JSON.parse(content);
  } catch (error) {
    console.error(`Unable to read valid JSON from ${filePath}`);
    console.error(error.message);
    process.exit(1);
  }
}

const schemaPath = path.join(
  root,
  "config",
  "takeover-audit",
  "schema",
  "questions.schema.json"
);

const dataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "questions.json"
);

const schema = readJson(schemaPath);
const data = readJson(dataPath);

const ajv = new Ajv2020({
  allErrors: true,
  strict: true,
  strictRequired: false,
  allowUnionTypes: true
});

addFormats(ajv);

const validate = ajv.compile(schema);
const valid = validate(data);

if (!valid) {
  console.error("Takeover Audit question catalogue is invalid:");

  for (const error of validate.errors ?? []) {
    console.error(`- ${error.instancePath || "/"}: ${error.message}`);
  }

  process.exit(1);
}

console.log("Takeover Audit question catalogue is valid.");
