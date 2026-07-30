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

async function rejectReports(database, reports, actionedBy) {
  let rejectedCount = 0;
  for (const report of reports) {
    // 신고를 읽은 뒤 갱신하기까지 remove-and-suspend가 상태를 바꿀 수 있으므로,
    // 트랜잭션 안에서 pending을 재확인해 action_pending/action_required로 전이된
    // 신고를 no_violation으로 덮지 않는다.
    const rejected = await database.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(report.ref);
      if (!snapshot.exists || snapshot.data().status !== "pending") {
        return false;
      }
      transaction.update(report.ref, {
        status: "rejected",
        resolution: "no_violation",
        resolvedAt: Timestamp.now(),
        actionedBy,
      });
      return true;
    });
    if (rejected) rejectedCount += 1;
  }
  return rejectedCount;
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
    // reject는 아직 조치하지 않은 pending 신고에만 적용한다. 상태 재확인과
    // 갱신은 rejectReports가 트랜잭션 안에서 원자적으로 수행한다.
    const rejectedCount = await rejectReports(
        database,
        group.reports,
        actionedBy,
    );
    return {...group, resolvedCount: rejectedCount};
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
