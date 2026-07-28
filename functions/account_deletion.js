const {FieldValue} = require("firebase-admin/firestore");

async function deleteAccountData({database, authentication, uid}) {
  const userRef = database.collection("users").doc(uid);
  const userSnapshot = await userRef.get();
  const nickname = userSnapshot.data() && userSnapshot.data().nickname;
  const [
    sharedSnapshot,
    ownedReports,
    submittedReports,
    ownedReportRequests,
    submittedReportRequests,
    reportedPosts,
    reactedPosts,
  ] = await Promise.all([
    database.collection("sharedPosts").where("ownerId", "==", uid).get(),
    database.collection("contentReports").where("ownerId", "==", uid).get(),
    database.collection("contentReports").where("reporterId", "==", uid).get(),
    database.collection("contentReportRequests")
        .where("ownerId", "==", uid).get(),
    database.collection("contentReportRequests")
        .where("reporterId", "==", uid).get(),
    database.collection("sharedPosts")
        .where("reportedBy", "array-contains", uid).get(),
    database.collection("sharedPosts")
        .where("reactedBy", "array-contains", uid).get(),
  ]);
  const writer = database.bulkWriter();
  for (const shared of sharedSnapshot.docs) writer.delete(shared.ref);
  const ownedPostPaths = new Set(
      sharedSnapshot.docs.map((shared) => shared.ref.path),
  );
  const identityPatches = new Map();
  for (const post of reportedPosts.docs) {
    if (ownedPostPaths.has(post.ref.path)) continue;
    identityPatches.set(post.ref.path, {
      reference: post.ref,
      data: {reportedBy: FieldValue.arrayRemove(uid)},
    });
  }
  for (const post of reactedPosts.docs) {
    if (ownedPostPaths.has(post.ref.path)) continue;
    const existing = identityPatches.get(post.ref.path);
    identityPatches.set(post.ref.path, {
      reference: post.ref,
      data: {
        ...(existing ? existing.data : {}),
        reactedBy: FieldValue.arrayRemove(uid),
      },
    });
  }
  for (const patch of identityPatches.values()) {
    writer.update(patch.reference, patch.data);
  }
  const reportReferences = new Map();
  for (const report of [...ownedReports.docs, ...submittedReports.docs]) {
    reportReferences.set(report.ref.path, report.ref);
  }
  for (const reportReference of reportReferences.values()) {
    writer.delete(reportReference);
  }
  const requestReferences = new Map();
  for (const request of [
    ...ownedReportRequests.docs,
    ...submittedReportRequests.docs,
  ]) {
    requestReferences.set(request.ref.path, request.ref);
  }
  for (const requestReference of requestReferences.values()) {
    writer.delete(requestReference);
  }
  writer.delete(database.collection("reportRateLimits").doc(uid));
  if (typeof nickname === "string" && nickname.trim()) {
    const nicknameRef = database.collection("nicknames")
        .doc(nickname.trim().toLowerCase());
    const nicknameSnapshot = await nicknameRef.get();
    if (nicknameSnapshot.data() &&
        nicknameSnapshot.data().ownerId === uid) {
      writer.delete(nicknameRef);
    }
  }
  await writer.close();
  await database.recursiveDelete(userRef);
  await authentication.deleteUser(uid);
}

module.exports = {deleteAccountData};
