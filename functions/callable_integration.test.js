const assert = require("node:assert/strict");
const test = require("node:test");
const {initializeApp: initializeAdminApp} = require("firebase-admin/app");
const {
  getFirestore: getAdminFirestore,
  Timestamp,
} = require("firebase-admin/firestore");
const {initializeApp, deleteApp} = require("firebase/app");
const {
  connectAuthEmulator,
  getAuth,
  signInAnonymously,
} = require("firebase/auth");
const {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} = require("firebase/functions");

const projectId = process.env.GCLOUD_PROJECT || "thebest-dev";
const hasEmulators = Boolean(
    process.env.FIRESTORE_EMULATOR_HOST &&
    process.env.FIREBASE_AUTH_EMULATOR_HOST,
);

let database;
let clientApp;
let reportSharedPost;

async function createPost(postId) {
  await database.collection("sharedPosts").doc(postId).set({
    ownerId: "owner",
    createdAt: Timestamp.now(),
    category: "직장",
    moodEmoji: "😤",
    moodLabel: "많이 화남",
    text: "오늘 회사에서 속상한 일이 있었어요.",
    storyId: postId,
    shared: true,
    reactions: [0, 0, 0],
    reactedBy: [],
    reportCount: 0,
  });
}

test.before(async () => {
  if (!hasEmulators) return;
  database = getAdminFirestore(initializeAdminApp({projectId}));
  clientApp = initializeApp(
      {projectId, apiKey: "demo-api-key"},
      `callable-test-${Date.now()}`,
  );
  const auth = getAuth(clientApp);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", {
    disableWarnings: true,
  });
  await signInAnonymously(auth);
  const functions = getFunctions(clientApp, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  reportSharedPost = httpsCallable(functions, "reportSharedPost");
});

test.after(async () => {
  if (clientApp) await deleteApp(clientApp);
});

test(
    "callable queues a private report and deduplicates the same reporter",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-dedupe-${Date.now()}`;
      await createPost(postId);

      const first = await reportSharedPost({postId, reason: "harassment"});
      const second = await reportSharedPost({postId, reason: "harassment"});
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();

      assert.equal(first.data.reportCount, 1);
      assert.equal(first.data.alreadyReported, false);
      assert.equal(second.data.alreadyReported, true);
      assert.equal(reports.size, 1);
      assert.equal(reports.docs[0].data().reason, "harassment");
      assert.equal(reports.docs[0].data().status, "pending");
    },
);

test(
    "callable accepts a legacy request without a reason",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-legacy-${Date.now()}`;
      await createPost(postId);

      const result = await reportSharedPost({postId});
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();

      assert.equal(result.data.reportCount, 1);
      assert.equal(reports.size, 1);
      assert.equal(reports.docs[0].data().reason, "legacy_unspecified");
    },
);
