const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

test("Firestore configuration only includes the deadline index", () => {
  const configuration = JSON.parse(fs.readFileSync(
      path.join(__dirname, "..", "firestore.indexes.json"),
      "utf8",
  ));
  assert.ok(configuration.indexes.some((index) => {
    return index.collectionGroup === "contentReports" &&
      index.fields.some((field) => field.fieldPath === "status") &&
      index.fields.some((field) => field.fieldPath === "deadlineAt");
  }));
  assert.deepEqual(configuration.fieldOverrides, []);
});
