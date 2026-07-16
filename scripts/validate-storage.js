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

function validateStorageIntegrity(storageCatalogue, processConfiguration) {
  const errors = [];
  const logicalKeys = new Set();
  const physicalNames = new Set();

  const catalogueMappings = new Map(
    storageCatalogue.entities.map((entity) => [
      entity.logicalKey,
      entity.physicalName
    ])
  );

  for (const entity of storageCatalogue.entities) {
    if (logicalKeys.has(entity.logicalKey)) {
      errors.push(`Duplicate storage logicalKey: ${entity.logicalKey}`);
    }

    logicalKeys.add(entity.logicalKey);

    if (physicalNames.has(entity.physicalName)) {
      errors.push(`Duplicate storage physicalName: ${entity.physicalName}`);
    }

    physicalNames.add(entity.physicalName);
  }

  for (const [logicalKey, physicalName] of Object.entries(
    processConfiguration.defaultStorageMappings
  )) {
    if (!catalogueMappings.has(logicalKey)) {
      errors.push(
        `Storage catalogue is missing default mapping: ${logicalKey}`
      );
      continue;
    }

    const cataloguePhysicalName = catalogueMappings.get(logicalKey);

    if (cataloguePhysicalName !== physicalName) {
      errors.push(
        `Storage mapping ${logicalKey} uses ${cataloguePhysicalName}; expected ${physicalName}`
      );
    }
  }

  for (const entity of storageCatalogue.entities) {
    if (
      !Object.hasOwn(
        processConfiguration.defaultStorageMappings,
        entity.logicalKey
      )
    ) {
      errors.push(
        `Storage catalogue contains unknown logicalKey: ${entity.logicalKey}`
      );
    }
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

const dataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "storage.json"
);

const processPath = path.join(
  root,
  "config",
  "takeover-audit",
  "process.json"
);

const schema = readJson(schemaPath);
const data = readJson(dataPath);
const processConfiguration = readJson(processPath);

const ajv = new Ajv2020({
  allErrors: true,
  strict: true,
  strictRequired: false
});

addFormats(ajv);

const validate = ajv.compile(schema);
const valid = validate(data);

if (!valid) {
  console.error("Takeover Audit storage catalogue is invalid:");

  for (const error of validate.errors ?? []) {
    console.error(`- ${error.instancePath || "/"}: ${error.message}`);
  }

  process.exit(1);
}

const integrityErrors = validateStorageIntegrity(
  data,
  processConfiguration
);

if (integrityErrors.length > 0) {
  console.error("Takeover Audit storage catalogue integrity checks failed:");

  for (const error of integrityErrors) {
    console.error(`- ${error}`);
  }

  process.exit(1);
}

console.log("Takeover Audit storage catalogue is valid.");