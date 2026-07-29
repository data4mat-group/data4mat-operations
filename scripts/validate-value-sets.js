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

const schemaPath = path.join(root, "config", "takeover-audit", "schema", "value-sets.schema.json");
const dataPath = path.join(root, "config", "takeover-audit", "value-sets.json");
const schema = readJson(schemaPath);
const data = readJson(dataPath);

const ajv = new Ajv2020({ allErrors: true, strict: true, strictRequired: false, allowUnionTypes: true });
addFormats(ajv);
const validate = ajv.compile(schema);
if (!validate(data)) {
  console.error("Takeover Audit reusable value-set catalogue is invalid:");
  for (const error of validate.errors ?? []) {
    console.error(`- ${error.instancePath || "/"}: ${error.message}`);
  }
  process.exit(1);
}

const ids = new Set();
for (const valueSet of data.valueSets) {
  if (ids.has(valueSet.valueSetId)) {
    console.error(`Duplicate valueSetId: ${valueSet.valueSetId}`);
    process.exit(1);
  }
  ids.add(valueSet.valueSetId);
  const values = new Set();
  const orders = new Set();
  for (const option of valueSet.values) {
    if (values.has(option.value)) {
      console.error(`Value set ${valueSet.valueSetId} contains duplicate value: ${option.value}`);
      process.exit(1);
    }
    if (orders.has(option.order)) {
      console.error(`Value set ${valueSet.valueSetId} contains duplicate order: ${option.order}`);
      process.exit(1);
    }
    values.add(option.value);
    orders.add(option.order);
  }
}

console.log("Takeover Audit reusable value-set catalogue is valid.");
