const {Timestamp} = require("firebase-admin/firestore");

const actionableStatuses = new Set([
  "pending",
  "action_pending",
  "action_required",
]);

async function reportGroup(database, reportId) {
  const seed = await database.collection("contentReports").doc(reportId).get();
  if (!seed.exists) throw new Error(`Report not found: ${reportId}`);
  const seedData = seed.data();
  const snapshot = await database.collection("contentReports")
      .where("postId", "==", seedData.postId)
      .get();
  const reports = snapshot.docs.filter(
      (report) => {
        const data = report.data();
        return data.ownerId === seedData.ownerId &&
          actionableStatuses.has(data.status);
      },
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
    actionedBy,
  });
}

async function markReportsActionPending(database, group, actionedBy) {
  await updateReports(database, group.reports, {
    status: "action_pending",
    resolution: "post_removal_and_user_suspension_pending",
    actionStartedAt: Timestamp.now(),
    actionedBy,
  });
}

async function removePostAndPrivateShare(database, group) {
  const postReference = database.collection("sharedPosts").doc(group.postId);
  const recordReference = database.collection("users").doc(group.ownerId)
      .collection("records").doc(group.postId);
  const suspensionReference = database.collection("moderationSuspensions")
      .doc(group.ownerId);
  await database.runTransaction(async (transaction) => {
    const [post, record] = await transaction.getAll(
        postReference,
        recordReference,
    );
    if (post.exists && post.data().ownerId === group.ownerId) {
      transaction.delete(postReference);
    }
    if (record.exists) transaction.update(recordReference, {shared: false});
    transaction.set(suspensionReference, {
      status: "suspended",
      reason: "content_report_violation",
      postId: group.postId,
      suspendedAt: Timestamp.now(),
    }, {merge: true});
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
    // 이미 제거·정지가 진행(action_pending) 또는 정지 실패로 재시도 대기
    // (action_required) 중인 신고는 no_violation으로 덮지 않는다. reject는
    // 아직 조치하지 않은 pending 신고에만 적용한다.
    const pendingReports = group.reports.filter(
        (report) => report.data().status === "pending",
    );
    if (pendingReports.length === 0) {
      return {...group, resolvedCount: 0};
    }
    await rejectReports(
        database,
        {...group, reports: pendingReports},
        actionedBy,
    );
    return {...group, resolvedCount: pendingReports.length};
  }
  if (action !== "remove-and-suspend") {
    throw new Error(`Unsupported moderation action: ${action}`);
  }
  await markReportsActionPending(database, group, actionedBy);
  await removePostAndPrivateShare(database, group);
  await suspendOwner(database, authentication, group, actionedBy);
  return {...group, resolvedCount: group.reports.length};
}

module.exports = {resolveContentReport};
