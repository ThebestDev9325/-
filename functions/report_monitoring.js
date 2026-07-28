const operationalReportStatuses = [
  "pending",
  "action_pending",
  "action_required",
];

function reportDeadlineEvent(status, deadlineAtMilliseconds, nowMilliseconds) {
  if (!operationalReportStatuses.includes(status) ||
      !Number.isFinite(deadlineAtMilliseconds) ||
      !Number.isFinite(nowMilliseconds)) {
    return null;
  }
  const overdue = deadlineAtMilliseconds <= nowMilliseconds;
  if (status === "pending") {
    return overdue ? "deadline_overdue" : "deadline_approaching";
  }
  return overdue ? "moderation_action_overdue" :
    "moderation_action_required";
}

module.exports = {
  operationalReportStatuses,
  reportDeadlineEvent,
};
