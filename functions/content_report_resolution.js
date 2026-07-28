const {Timestamp} = require("firebase-admin/firestore");

const actionableStatuses = new Set([
  "pending",
  "action_pending",
  "action_required",
]);
const retentionMilliseconds = 90 * 24 * 60 * 60 * 1000;

function expirationFrom(timestamp) {
  return Timestamp.fromMillis(timestamp.toMillis() + retentionMilliseconds);
}

async function reportGroup(database, reportId) {
  const seed = await database.collection("contentReports").doc(reportId).get();
  if (!seed.exists) throw new Error(`Report not found: ${reportId}`);
  const seedData = seed.data();
  const snapshot = await database.collection("contentReports")
      .where("postId", "==", seedData.postId)
      .get();
  const reports = snapshot.docs.filter(
      (report) => actionableStatuses.has(report.data().status),
  );
  return {
    ownerId: String(seedData.ownerId),
    postId: String(seedData.postId),
    reports,
  };
}

async function updateReports(database, reports, data) {
  if (reports.length === 0) return;
  const writer = database.bulkWriter();
  for (const report of reports) writer.update(report.ref, data);
  await writer.close();
}

async function rejectReports(database, group, actionedBy) {
  const resolvedAt = Timestamp.now();
  await updateReports(database, group.reports, {
    status: "rejected",
    resolution: "no_violation",
    resolvedAt,
    expiresAt: expirationFrom(resolvedAt),
    actionedBy,
  });
}

async function markPostRemoved(database, group, actionedBy) {
  const postReference = database.collection("sharedPosts").doc(group.postId);
  const recordReference = database.collection("users").doc(group.ownerId)
      .collection("records").doc(group.postId);
  await database.runTransaction(async (transaction) => {
    const references = [
      postReference,
      recordReference,
      ...group.reports.map((report) => report.ref),
    ];
    const snapshots = await transaction.getAll(...references);
    const [post, record, ...reports] = snapshots;
    if (post.exists) transaction.delete(postReference);
    if (record.exists) transaction.update(recordReference, {shared: false});
    const actionStartedAt = Timestamp.now();
    for (const report of reports) {
      if (!report.exists ||
          !actionableStatuses.has(report.data().status)) {
        continue;
      }
      transaction.update(report.ref, {
        status: "action_pending",
        resolution: "post_removed_user_suspension_pending",
        actionStartedAt,
        actionedBy,
      });
    }
  });
}

async function suspendOwner(
    database,
    authentication,
    group,
    actionedBy,
) {
  try {
    await authentication.updateUser(group.ownerId, {disabled: true});
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      await updateReports(database, group.reports, {
        status: "action_required",
        resolution: "post_removed_user_suspension_failed",
        suspensionError: String(error.message || error).slice(0, 500),
        actionedBy,
      });
      throw error;
    }
  }

  const resolvedAt = Timestamp.now();
  await updateReports(database, group.reports, {
    status: "resolved",
    resolution: "post_removed_and_user_suspended",
    resolvedAt,
    suspendedAt: resolvedAt,
    expiresAt: expirationFrom(resolvedAt),
    actionedBy,
    suspensionError: null,
  });
}

async function resolveContentReport({
  database,
  authentication,
  reportId,
  action,
  actionedBy,
}) {
  const group = await reportGroup(database, reportId);
  if (group.reports.length === 0) {
    return {...group, resolvedCount: 0};
  }
  if (action === "reject") {
    await rejectReports(database, group, actionedBy);
    return {...group, resolvedCount: group.reports.length};
  }
  if (action !== "remove-and-suspend") {
    throw new Error(`Unsupported moderation action: ${action}`);
  }
  await markPostRemoved(database, group, actionedBy);
  await suspendOwner(database, authentication, group, actionedBy);
  return {...group, resolvedCount: group.reports.length};
}

module.exports = {resolveContentReport};
