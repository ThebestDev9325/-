const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

test("Firestore configuration includes the deadline index and report TTL", () => {
  const configuration = JSON.parse(fs.readFileSync(
      path.join(__dirname, "..", "firestore.indexes.json"),
      "utf8",
  ));
  assert.ok(configuration.indexes.some((index) => {
    return index.collectionGroup === "contentReports" &&
      index.fields.some((field) => field.fieldPath === "status") &&
      index.fields.some((field) => field.fieldPath === "deadlineAt");
  }));
  assert.ok(configuration.fieldOverrides.some((override) => {
    return override.collectionGroup === "contentReports" &&
      override.fieldPath === "expiresAt" &&
      override.ttl === true;
  }));
});
