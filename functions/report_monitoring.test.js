const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {reportDeadlineEvent} = require("./report_monitoring");

test("pending report deadlines distinguish approaching and overdue", () => {
  assert.equal(
      reportDeadlineEvent("pending", 2000, 1000),
      "deadline_approaching",
  );
  assert.equal(
      reportDeadlineEvent("pending", 1000, 1000),
      "deadline_overdue",
  );
});

test("incomplete moderation actions remain operational alerts", () => {
  assert.equal(
      reportDeadlineEvent("action_pending", 2000, 1000),
      "moderation_action_required",
  );
  assert.equal(
      reportDeadlineEvent("action_required", 1000, 2000),
      "moderation_action_overdue",
  );
  assert.equal(reportDeadlineEvent("resolved", 1000, 2000), null);
});

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
