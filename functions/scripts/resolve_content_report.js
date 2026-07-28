const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");

initializeApp({credential: applicationDefault()});
const database = getFirestore();

const [reportId, action] = process.argv.slice(2);
const allowedActions = new Set(["remove-and-suspend", "reject"]);
if (!reportId || !allowedActions.has(action)) {
  process.stderr.write(
      "Usage: node scripts/resolve_content_report.js <reportId> " +
      "<remove-and-suspend|reject>\n",
  );
  process.exit(2);
}

const actionedBy = process.env.MODERATOR_EMAIL || "a01041989325@gmail.com";

async function rejectReport(reportReference) {
  await reportReference.update({
    status: "rejected",
    resolution: "no_violation",
    resolvedAt: Timestamp.now(),
    actionedBy,
  });
}

async function removePost(reportReference) {
  return database.runTransaction(async (transaction) => {
    const report = await transaction.get(reportReference);
    if (!report.exists) throw new Error(`Report not found: ${reportId}`);
    const data = report.data();
    const postReference = database.collection("sharedPosts").doc(data.postId);
    const recordReference = database.collection("users").doc(data.ownerId)
        .collection("records").doc(data.postId);
    const post = await transaction.get(postReference);
    const record = await transaction.get(recordReference);
    if (post.exists) transaction.delete(postReference);
    if (record.exists) transaction.update(recordReference, {shared: false});
    transaction.update(reportReference, {
      status: "resolved",
      resolution: "post_removed",
      resolvedAt: Timestamp.now(),
      actionedBy,
    });
    return String(data.ownerId);
  });
}

async function main() {
  const reportReference = database.collection("contentReports").doc(reportId);
  if (action === "reject") {
    await rejectReport(reportReference);
    process.stdout.write(`Rejected report ${reportId}.\n`);
    return;
  }

  const ownerId = await removePost(reportReference);
  try {
    await getAuth().updateUser(ownerId, {disabled: true});
    await reportReference.update({
      resolution: "post_removed_and_user_suspended",
      suspendedAt: Timestamp.now(),
    });
  } catch (error) {
    await reportReference.update({
      status: "action_required",
      resolution: "post_removed_user_suspension_failed",
      suspensionError: String(error.message || error).slice(0, 500),
    });
    throw error;
  }
  process.stdout.write(`Resolved report ${reportId} and suspended ${ownerId}.\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error}\n`);
  process.exitCode = 1;
});
