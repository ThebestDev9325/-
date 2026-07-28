const {Timestamp} = require("firebase-admin/firestore");
const {createHash} = require("node:crypto");

const reportDeadlineMilliseconds = 24 * 60 * 60 * 1000;

function reportDocumentId(postId, reporterId) {
  const reporterHash = createHash("sha256").update(reporterId).digest("hex");
  return `${postId}_${reporterHash}`;
}

async function migratePost(database, postReference) {
  return database.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postReference);
    if (!snapshot.exists) return 0;
    const data = snapshot.data();
    const reporters = Array.isArray(data.reportedBy) ?
      data.reportedBy.filter((value) => typeof value === "string") :
      [];
    if (reporters.length === 0) return 0;
    const migratedAt = Timestamp.now();
    const reportReferences = reporters.map((reporterId) => {
      return database.collection("contentReports")
          .doc(reportDocumentId(snapshot.id, reporterId));
    });
    const existingReports = await transaction.getAll(...reportReferences);
    let migratedCount = 0;
    for (let index = 0; index < reporters.length; index++) {
      if (existingReports[index].exists) continue;
      const reporterId = reporters[index];
      const reportReference = reportReferences[index];
      transaction.set(reportReference, {
        postId: snapshot.id,
        ownerId: String(data.ownerId || ""),
        reporterId,
        reason: "legacy_unspecified",
        status: "pending",
        createdAt: migratedAt,
        deadlineAt: Timestamp.fromMillis(
            migratedAt.toMillis() + reportDeadlineMilliseconds,
        ),
        snapshot: {
          category: String(data.category || ""),
          text: String(data.text || "").slice(0, 2000),
          createdAt: data.createdAt || migratedAt,
        },
        migratedAt,
      });
      migratedCount++;
    }
    return migratedCount;
  });
}

module.exports = {migratePost, reportDocumentId};
