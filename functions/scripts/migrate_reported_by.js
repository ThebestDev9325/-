const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {
  FieldPath,
  FieldValue,
  getFirestore,
  Timestamp,
} = require("firebase-admin/firestore");
const {createHash} = require("node:crypto");

initializeApp({credential: applicationDefault()});
const database = getFirestore();

function reportDocumentId(postId, reporterId) {
  const reporterHash = createHash("sha256").update(reporterId).digest("hex");
  return `${postId}_${reporterHash}`;
}

async function migratePost(postReference) {
  return database.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postReference);
    if (!snapshot.exists) return 0;
    const data = snapshot.data();
    const reporters = Array.isArray(data.reportedBy) ?
      data.reportedBy.filter((value) => typeof value === "string") :
      [];
    const migratedAt = Timestamp.now();
    for (const reporterId of reporters) {
      const reportReference = database.collection("contentReports")
          .doc(reportDocumentId(snapshot.id, reporterId));
      transaction.set(reportReference, {
        postId: snapshot.id,
        ownerId: String(data.ownerId || ""),
        reporterId,
        reason: "legacy_unspecified",
        status: "migrated",
        createdAt: migratedAt,
        migratedAt,
      }, {merge: true});
    }
    if ("reportedBy" in data) {
      transaction.update(postReference, {reportedBy: FieldValue.delete()});
    }
    return reporters.length;
  });
}

async function main() {
  let lastDocument;
  let migratedPosts = 0;
  let migratedReporters = 0;
  while (true) {
    let query = database.collection("sharedPosts")
        .orderBy(FieldPath.documentId())
        .limit(100);
    if (lastDocument) query = query.startAfter(lastDocument);
    const snapshot = await query.get();
    if (snapshot.empty) break;
    for (const document of snapshot.docs) {
      const count = await migratePost(document.ref);
      if (count > 0) migratedPosts++;
      migratedReporters += count;
    }
    lastDocument = snapshot.docs.at(-1);
  }
  process.stdout.write(
      `Migrated ${migratedReporters} reports from ${migratedPosts} posts.\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error}\n`);
  process.exitCode = 1;
});
