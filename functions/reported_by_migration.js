const {Timestamp} = require("firebase-admin/firestore");
const {
  legacyReportDocumentId,
  reportDocumentId,
} = require("./content_report_identity");

const reportDeadlineMilliseconds = 24 * 60 * 60 * 1000;

async function migratePost(database, postReference) {
  return database.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postReference);
    if (!snapshot.exists) return 0;
    const data = snapshot.data();
    const reporters = Array.isArray(data.reportedBy) ?
      data.reportedBy.filter((value) => typeof value === "string") :
      [];
    if (reporters.length === 0) return 0;
    const ownerId = String(data.ownerId || "");
    const migratedAt = Timestamp.now();
    const reportReferences = reporters.map((reporterId) => {
      return database.collection("contentReports")
          .doc(reportDocumentId(snapshot.id, ownerId, reporterId));
    });
    const legacyReportReferences = reporters.map((reporterId) => {
      return database.collection("contentReports")
          .doc(legacyReportDocumentId(snapshot.id, reporterId));
    });
    const existingReports = await transaction.getAll(
        ...reportReferences,
        ...legacyReportReferences,
    );
    let migratedCount = 0;
    for (let index = 0; index < reporters.length; index++) {
      const currentReport = existingReports[index];
      const legacyReport = existingReports[index + reporters.length];
      const matchingLegacyReport = legacyReport.exists &&
        legacyReport.data().ownerId === ownerId;
      if (currentReport.exists || matchingLegacyReport) continue;
      const reporterId = reporters[index];
      const reportReference = reportReferences[index];
      transaction.set(reportReference, {
        postId: snapshot.id,
        ownerId,
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
    transaction.update(postReference, {reportedBy: []});
    return migratedCount;
  });
}

module.exports = {
  legacyReportDocumentId,
  migratePost,
  reportDocumentId,
};
