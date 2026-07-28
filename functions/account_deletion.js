async function deleteAccountData({database, authentication, uid}) {
  const userRef = database.collection("users").doc(uid);
  const userSnapshot = await userRef.get();
  const nickname = userSnapshot.data() && userSnapshot.data().nickname;
  const [sharedSnapshot, ownedReports, submittedReports] = await Promise.all([
    database.collection("sharedPosts").where("ownerId", "==", uid).get(),
    database.collection("contentReports").where("ownerId", "==", uid).get(),
    database.collection("contentReports").where("reporterId", "==", uid).get(),
  ]);
  const writer = database.bulkWriter();
  for (const shared of sharedSnapshot.docs) writer.delete(shared.ref);
  const reportReferences = new Map();
  for (const report of [...ownedReports.docs, ...submittedReports.docs]) {
    reportReferences.set(report.ref.path, report.ref);
  }
  for (const reportReference of reportReferences.values()) {
    writer.delete(reportReference);
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
