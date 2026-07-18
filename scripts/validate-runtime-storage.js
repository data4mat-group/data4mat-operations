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

function validateCatalogueIntegrity(runtimeCatalogue, operationalCatalogue) {
  const errors = [];
  const runtimeLogicalKeys = new Set();
  const runtimePhysicalNames = new Set();

  for (const entity of runtimeCatalogue.entities) {
    if (runtimeLogicalKeys.has(entity.logicalKey)) {
      errors.push(`Duplicate runtime logicalKey: ${entity.logicalKey}`);
    }
    runtimeLogicalKeys.add(entity.logicalKey);

    if (runtimePhysicalNames.has(entity.physicalName)) {
      errors.push(`Duplicate runtime physicalName: ${entity.physicalName}`);
    }
    runtimePhysicalNames.add(entity.physicalName);
  }

  const operationalLogicalKeys = new Set(
    operationalCatalogue.entities.map((entity) => entity.logicalKey)
  );

  const operationalPhysicalNames = new Set(
    operationalCatalogue.entities.map((entity) => entity.physicalName)
  );

  for (const entity of runtimeCatalogue.entities) {
    if (operationalLogicalKeys.has(entity.logicalKey)) {
      errors.push(
        `Runtime logicalKey conflicts with operational storage: ${entity.logicalKey}`
      );
    }

    if (operationalPhysicalNames.has(entity.physicalName)) {
      errors.push(
        `Runtime physicalName conflicts with operational storage: ${entity.physicalName}`
      );
    }
  }

  if (runtimeCatalogue.platform !== operationalCatalogue.platform) {
    errors.push(
      `Runtime platform ${runtimeCatalogue.platform} does not match operational platform ${operationalCatalogue.platform}`
    );
  }

  return errors;
}

const schemaPath = path.join(
  root,
  "config",
  "takeover-audit",
  "schema",
  "storage.schema.json"
);

const runtimeDataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "runtime-storage.json"
);

const operationalDataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "storage.json"
);

const schema = readJson(schemaPath);
const runtimeData = readJson(runtimeDataPath);
const operationalData = readJson(operationalDataPath);

const ajv = new Ajv2020({
  allErrors: true,
  strict: true,
  strictRequired: false
});

addFormats(ajv);

const validate = ajv.compile(schema);
const valid = validate(runtimeData);

if (!valid) {
  console.error("Takeover Audit runtime storage catalogue is invalid:");

  for (const error of validate.errors ?? []) {
    console.error(`- ${error.instancePath || "/"}: ${error.message}`);
  }

  process.exit(1);
}

const integrityErrors = validateCatalogueIntegrity(
  runtimeData,
  operationalData
);

if (integrityErrors.length > 0) {
  console.error(
    "Takeover Audit runtime storage catalogue integrity checks failed:"
  );

  for (const error of integrityErrors) {
    console.error(`- ${error}`);
  }

  process.exit(1);
}

console.log("Takeover Audit runtime storage catalogue is valid.");
