const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {
  FieldPath,
  getFirestore,
} = require("firebase-admin/firestore");
const {migratePost} = require("../reported_by_migration");

initializeApp({credential: applicationDefault()});
const database = getFirestore();

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
      const count = await migratePost(database, document.ref);
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
