const assert = require("node:assert/strict");
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
