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

function validateCatalogueIntegrity(catalogue, processConfiguration, valueSetConfiguration) {
  const errors = [];

  const stageIds = new Set(
    processConfiguration.stages.map((stage) => stage.stageId)
  );

  const supportedResponseTypes = new Set(catalogue.supportedResponseTypes);
  const valueSetIds = new Set(valueSetConfiguration.valueSets.map((valueSet) => valueSet.valueSetId));
  const activeQuestionCountByStage = new Map();
  const questionOrdersByStage = new Map();
  const questionIds = new Set();
  const blockingRuleIds = new Set();

  for (const stageId of stageIds) {
    activeQuestionCountByStage.set(stageId, 0);
    questionOrdersByStage.set(stageId, new Set());
  }

  for (const question of catalogue.questions) {
    if (questionIds.has(question.questionId)) {
      errors.push(`Duplicate questionId: ${question.questionId}`);
    }

    questionIds.add(question.questionId);

    if (!stageIds.has(question.stageId)) {
      errors.push(
        `Question ${question.questionId} references unknown stageId: ${question.stageId}`
      );
    }

    if (!supportedResponseTypes.has(question.responseType)) {
      errors.push(
        `Question ${question.questionId} uses unsupported responseType: ${question.responseType}`
      );
    }

    if (question.active && stageIds.has(question.stageId)) {
      activeQuestionCountByStage.set(
        question.stageId,
        activeQuestionCountByStage.get(question.stageId) + 1
      );
    }

    if (stageIds.has(question.stageId)) {
      const stageOrders = questionOrdersByStage.get(question.stageId);

      if (stageOrders.has(question.order)) {
        errors.push(
          `Stage ${question.stageId} contains duplicate question order: ${question.order}`
        );
      }

      stageOrders.add(question.order);
    }

    for (const rule of question.blockingRules ?? []) {
      if (blockingRuleIds.has(rule.ruleId)) {
        errors.push(`Duplicate blocking ruleId: ${rule.ruleId}`);
      }

      blockingRuleIds.add(rule.ruleId);
    }

    if (question.responseType === "RepeatingCollection") {
      const fieldIds = new Set();

      for (const field of question.collection.fields) {
        if (fieldIds.has(field.fieldId)) {
          errors.push(
            `Question ${question.questionId} contains duplicate collection fieldId: ${field.fieldId}`
          );
        }

        fieldIds.add(field.fieldId);

        if (!supportedResponseTypes.has(field.responseType)) {
          errors.push(
            `Question ${question.questionId}, field ${field.fieldId} uses unsupported responseType: ${field.responseType}`
          );
        }

        if (field.valueSetId && !valueSetIds.has(field.valueSetId)) {
          errors.push(
            `Question ${question.questionId}, field ${field.fieldId} references unknown valueSetId: ${field.valueSetId}`
          );
        }

        const choiceValues = new Set();

        for (const choice of field.choices ?? []) {
          if (choiceValues.has(choice.value)) {
            errors.push(
              `Question ${question.questionId}, field ${field.fieldId} contains duplicate choice value: ${choice.value}`
            );
          }

          choiceValues.add(choice.value);
        }
      }
    }

    const choiceValues = new Set();

    for (const choice of question.choices ?? []) {
      if (choiceValues.has(choice.value)) {
        errors.push(
          `Question ${question.questionId} contains duplicate choice value: ${choice.value}`
        );
      }

      choiceValues.add(choice.value);
    }
  }

  for (const stage of processConfiguration.stages) {
    const activeQuestionCount =
      activeQuestionCountByStage.get(stage.stageId) ?? 0;

    if (activeQuestionCount === 0) {
      errors.push(
        `Stage ${stage.stageId} has no active questions in the catalogue`
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
  "questions.schema.json"
);

const dataPath = path.join(
  root,
  "config",
  "takeover-audit",
  "questions.json"
);

const processPath = path.join(
  root,
  "config",
  "takeover-audit",
  "process.json"
);

const valueSetsPath = path.join(
  root,
  "config",
  "takeover-audit",
  "value-sets.json"
);

const schema = readJson(schemaPath);
const data = readJson(dataPath);
const processConfiguration = readJson(processPath);
const valueSetConfiguration = readJson(valueSetsPath);

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

const integrityErrors = validateCatalogueIntegrity(
  data,
  processConfiguration,
  valueSetConfiguration
);

if (integrityErrors.length > 0) {
  console.error("Takeover Audit question catalogue integrity checks failed:");

  for (const error of integrityErrors) {
    console.error(`- ${error}`);
  }

  process.exit(1);
}

console.log("Takeover Audit question catalogue is valid.");
