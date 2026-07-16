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

function validateProcessIntegrity(
  processConfiguration,
  questionCatalogue
) {
  const errors = [];
  const defaultMappings = processConfiguration.defaultStorageMappings;
  const allowedMappingKeys = new Set(Object.keys(defaultMappings));

  const storageEntityMappingKeys = {
    AuditResponse: "response",
    Finding: "finding",
    Evidence: "evidence",
    RemediationAction: "remediationAction",
    Approval: "approval"
  };

  const stagesById = new Map(
    processConfiguration.stages.map((stage) => [stage.stageId, stage])
  );

  const stageIds = new Set();
  const stageCodes = new Set();
  const stageOrders = new Set();
  const hardStopRuleIds = new Set();

  for (const stage of processConfiguration.stages) {
    if (stageIds.has(stage.stageId)) {
      errors.push(`Duplicate stageId: ${stage.stageId}`);
    }

    stageIds.add(stage.stageId);

    if (stageCodes.has(stage.code)) {
      errors.push(`Duplicate stage code: ${stage.code}`);
    }

    stageCodes.add(stage.code);

    if (stageOrders.has(stage.order)) {
      errors.push(`Duplicate stage order: ${stage.order}`);
    }

    stageOrders.add(stage.order);

    for (const mappingKey of Object.keys(stage.storageMappings)) {
      if (!allowedMappingKeys.has(mappingKey)) {
        errors.push(
          `Stage ${stage.stageId} uses unknown storage mapping key: ${mappingKey}`
        );
        continue;
      }

      const expectedStorageName = defaultMappings[mappingKey];
      const actualStorageName = stage.storageMappings[mappingKey];

      if (actualStorageName !== expectedStorageName) {
        errors.push(
          `Stage ${stage.stageId} maps ${mappingKey} to ${actualStorageName}; expected ${expectedStorageName}`
        );
      }
    }

    if (!Object.hasOwn(stage.storageMappings, "stage")) {
      errors.push(
        `Stage ${stage.stageId} is missing required storage mapping: stage`
      );
    }

    for (const rule of stage.hardStopRules ?? []) {
      if (hardStopRuleIds.has(rule.ruleId)) {
        errors.push(`Duplicate hard-stop ruleId: ${rule.ruleId}`);
      }

      hardStopRuleIds.add(rule.ruleId);
    }
  }

  for (const stage of processConfiguration.stages) {
    if (
      stage.previousStageId !== null &&
      !stagesById.has(stage.previousStageId)
    ) {
      errors.push(
        `Stage ${stage.stageId} references unknown previousStageId: ${stage.previousStageId}`
      );
    }

    if (
      stage.nextStageId !== null &&
      !stagesById.has(stage.nextStageId)
    ) {
      errors.push(
        `Stage ${stage.stageId} references unknown nextStageId: ${stage.nextStageId}`
      );
    }

    if (stage.previousStageId !== null) {
      const previousStage = stagesById.get(stage.previousStageId);

      if (
        previousStage &&
        previousStage.nextStageId !== stage.stageId
      ) {
        errors.push(
          `Stage ${stage.stageId} names ${stage.previousStageId} as its previous stage, but that stage does not point back to ${stage.stageId}`
        );
      }
    }

    if (stage.nextStageId !== null) {
      const nextStage = stagesById.get(stage.nextStageId);

      if (
        nextStage &&
        nextStage.previousStageId !== stage.stageId
      ) {
        errors.push(
          `Stage ${stage.stageId} names ${stage.nextStageId} as its next stage, but that stage does not point back to ${stage.stageId}`
        );
      }
    }
  }

  const requiredMappingsByStage = new Map();

  for (const stage of processConfiguration.stages) {
    requiredMappingsByStage.set(stage.stageId, new Set(["stage"]));
  }

  for (const question of questionCatalogue.questions) {
    if (!question.active) {
      continue;
    }

    if (!stagesById.has(question.stageId)) {
      continue;
    }

    const requiredMappings = requiredMappingsByStage.get(
      question.stageId
    );

    const storageMappingKey =
      storageEntityMappingKeys[question.storageEntity];

    if (!storageMappingKey) {
      errors.push(
        `Question ${question.questionId} uses an unmapped storageEntity: ${question.storageEntity}`
      );
    } else {
      requiredMappings.add(storageMappingKey);
    }

    if (question.createsFinding) {
      requiredMappings.add("finding");
    }

    if (question.evidenceRequired) {
      requiredMappings.add("evidence");
    }
  }

  for (const stage of processConfiguration.stages) {
    const requiredMappings = requiredMappingsByStage.get(stage.stageId);

    for (const mappingKey of requiredMappings) {
      if (!Object.hasOwn(defaultMappings, mappingKey)) {
        errors.push(
          `Required storage mapping ${mappingKey} is missing from defaultStorageMappings`
        );
        continue;
      }

      if (!Object.hasOwn(stage.storageMappings, mappingKey)) {
        errors.push(
          `Stage ${stage.stageId} is missing required storage mapping: ${mappingKey}`
        );
      }
    }
  }

  return errors;
}

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

const questionsPath = path.join(
  root,
  "config",
  "takeover-audit",
  "questions.json"
);

const schema = readJson(schemaPath);
const data = readJson(dataPath);
const questionCatalogue = readJson(questionsPath);

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
    console.error(`- ${error.instancePath || "/"}: ${error.message}`);
  }

  process.exit(1);
}

const integrityErrors = validateProcessIntegrity(
  data,
  questionCatalogue
);

if (integrityErrors.length > 0) {
  console.error("Takeover Audit process integrity checks failed:");

  for (const error of integrityErrors) {
    console.error(`- ${error}`);
  }

  process.exit(1);
}

console.log("Takeover Audit process configuration is valid.");