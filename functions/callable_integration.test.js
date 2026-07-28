const assert = require("node:assert/strict");
const test = require("node:test");
const {initializeApp: initializeAdminApp} = require("firebase-admin/app");
const {getAuth: getAdminAuth} = require("firebase-admin/auth");
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
const {deleteAccountData} = require("./account_deletion");
const {resolveContentReport} = require("./content_report_resolution");
const {
  migratePost,
  reportDocumentId,
} = require("./reported_by_migration");

const projectId = process.env.GCLOUD_PROJECT || "thebest-dev";
const hasEmulators = Boolean(
    process.env.FIRESTORE_EMULATOR_HOST &&
    process.env.FIREBASE_AUTH_EMULATOR_HOST,
);

let database;
let clientApp;
let clientUserId;
let publishSharedRecord;
let reportSharedPost;

async function createPost(postId, ownerId = "owner") {
  await database.collection("sharedPosts").doc(postId).set({
    ownerId,
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

async function createAnonymousReporter(name) {
  const app = initializeApp(
      {projectId, apiKey: "demo-api-key"},
      `reporter-${name}-${Date.now()}`,
  );
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", {
    disableWarnings: true,
  });
  await signInAnonymously(auth);
  const functions = getFunctions(app, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  return {
    app,
    report: httpsCallable(functions, "reportSharedPost"),
  };
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
  const credential = await signInAnonymously(auth);
  clientUserId = credential.user.uid;
  const functions = getFunctions(clientApp, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  publishSharedRecord = httpsCallable(functions, "publishSharedRecord");
  reportSharedPost = httpsCallable(functions, "reportSharedPost");
});

test.after(async () => {
  if (clientApp) await deleteApp(clientApp);
});

test(
    "callable validates a private record before publishing it",
    {skip: !hasEmulators},
    async () => {
      const recordId = `publish-valid-${Date.now()}`;
      const recordReference = database.collection("users").doc(clientUserId)
          .collection("records").doc(recordId);
      await recordReference.set({
        ownerId: clientUserId,
        createdAt: Timestamp.now(),
        category: "직장",
        moodEmoji: "😤",
        moodLabel: "많이 화남",
        text: "오늘 회사에서 속상한 일이 있었어요.",
        storyId: recordId,
        shared: false,
      });

      const result = await publishSharedRecord({recordId});
      const post = await database.collection("sharedPosts").doc(recordId).get();
      const record = await recordReference.get();

      assert.equal(result.data.published, true);
      assert.equal(post.data().ownerId, clientUserId);
      assert.deepEqual(post.data().reportedBy, []);
      assert.equal(record.data().shared, true);
    },
);

test(
    "moderation resolves every report only after the owner is suspended",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `moderation-owner-${Date.now()}`;
      const postId = `moderation-post-${Date.now()}`;
      const authentication = getAdminAuth();
      await authentication.createUser({uid: ownerId});
      await createPost(postId, ownerId);
      await database.collection("users").doc(ownerId)
          .collection("records").doc(postId).set({shared: true});
      const reportReferences = ["report-a", "report-b"].map((suffix) => {
        return database.collection("contentReports")
            .doc(`${postId}-${suffix}`);
      });
      await Promise.all(reportReferences.map((reference, index) => {
        return reference.set({
          postId,
          ownerId,
          reporterId: `reporter-${index}`,
          status: "pending",
          deadlineAt: Timestamp.now(),
        });
      }));

      const result = await resolveContentReport({
        database,
        authentication,
        reportId: reportReferences[0].id,
        action: "remove-and-suspend",
        actionedBy: "moderator@example.com",
      });
      const reports = await Promise.all(
          reportReferences.map((reference) => reference.get()),
      );
      const post = await database.collection("sharedPosts").doc(postId).get();
      const record = await database.collection("users").doc(ownerId)
          .collection("records").doc(postId).get();
      const owner = await authentication.getUser(ownerId);

      assert.equal(result.resolvedCount, 2);
      assert.equal(post.exists, false);
      assert.equal(record.data().shared, false);
      assert.ok(reports.every((report) => report.data().status === "resolved"));
      assert.ok(reports.every((report) => report.data().resolvedAt));
      assert.equal(owner.disabled, true);
      await authentication.deleteUser(ownerId);
    },
);

test(
    "a suspension failure leaves every report retryable",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `moderation-failure-owner-${Date.now()}`;
      const postId = `moderation-failure-post-${Date.now()}`;
      await createPost(postId, ownerId);
      const reportReferences = ["report-a", "report-b"].map((suffix) => {
        return database.collection("contentReports")
            .doc(`${postId}-${suffix}`);
      });
      await Promise.all(reportReferences.map((reference, index) => {
        return reference.set({
          postId,
          ownerId,
          reporterId: `reporter-${index}`,
          status: "pending",
          deadlineAt: Timestamp.now(),
        });
      }));
      const authentication = {
        updateUser: async () => {
          const error = new Error("temporary auth failure");
          error.code = "auth/internal-error";
          throw error;
        },
      };

      await assert.rejects(
          resolveContentReport({
            database,
            authentication,
            reportId: reportReferences[0].id,
            action: "remove-and-suspend",
            actionedBy: "moderator@example.com",
          }),
      );
      const reports = await Promise.all(
          reportReferences.map((reference) => reference.get()),
      );

      assert.ok(
          reports.every(
              (report) => report.data().status === "action_required",
          ),
      );
      assert.ok(reports.every((report) => report.data().suspensionError));
    },
);

test(
    "callable rejects an objectionable private record before it is public",
    {skip: !hasEmulators},
    async () => {
      const recordId = `publish-invalid-${Date.now()}`;
      const recordReference = database.collection("users").doc(clientUserId)
          .collection("records").doc(recordId);
      await recordReference.set({
        ownerId: clientUserId,
        createdAt: Timestamp.now(),
        category: "직장",
        moodEmoji: "😤",
        moodLabel: "많이 화남",
        text: "씨발 꺼져",
        storyId: recordId,
        shared: false,
      });

      await assert.rejects(publishSharedRecord({recordId}));
      const post = await database.collection("sharedPosts").doc(recordId).get();
      const record = await recordReference.get();

      assert.equal(post.exists, false);
      assert.equal(record.data().shared, false);
    },
);

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
      assert.deepEqual(
          (await database.collection("sharedPosts").doc(postId).get())
              .data().reportedBy,
          [clientUserId],
      );
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

test(
    "callable backfills a legacy reporter without counting it twice",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-migrated-${Date.now()}`;
      await createPost(postId);
      await database.collection("sharedPosts").doc(postId).update({
        reportedBy: [clientUserId],
        reportCount: 1,
      });

      const result = await reportSharedPost({postId, reason: "spam"});
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();

      assert.equal(result.data.reportCount, 1);
      assert.equal(result.data.alreadyReported, true);
      assert.equal(reports.size, 1);
      assert.equal(reports.docs[0].data().status, "pending");
      assert.ok(reports.docs[0].data().deadlineAt);
    },
);

test(
    "reports from five anonymous accounts never delete a post globally",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-sybil-${Date.now()}`;
      await createPost(postId);
      const reporters = await Promise.all(
          Array.from({length: 5}, (_, index) => {
            return createAnonymousReporter(String(index));
          }),
      );
      try {
        await Promise.all(
            reporters.map(({report}) => {
              return report({postId, reason: "harassment"});
            }),
        );
        const post = await database.collection("sharedPosts").doc(postId).get();
        const reports = await database.collection("contentReports")
            .where("postId", "==", postId)
            .get();

        assert.equal(post.exists, true);
        assert.equal(post.data().reportCount, 5);
        assert.equal(reports.size, 5);
      } finally {
        await Promise.all(reporters.map(({app}) => deleteApp(app)));
      }
    },
);

test(
    "an anonymous reporter is limited to ten reports per hour",
    {skip: !hasEmulators},
    async () => {
      const reporter = await createAnonymousReporter("rate-limit");
      const prefix = `callable-rate-${Date.now()}`;
      try {
        for (let index = 0; index < 11; index++) {
          await createPost(`${prefix}-${index}`);
        }
        for (let index = 0; index < 10; index++) {
          await reporter.report({
            postId: `${prefix}-${index}`,
            reason: "spam",
          });
        }
        await assert.rejects(
            reporter.report({
              postId: `${prefix}-10`,
              reason: "spam",
            }),
            (error) => error.code === "functions/resource-exhausted",
        );
        const untouchedPost = await database.collection("sharedPosts")
            .doc(`${prefix}-10`).get();
        assert.equal(untouchedPost.data().reportCount, 0);
      } finally {
        await deleteApp(reporter.app);
      }
    },
);

test(
    "account deletion removes reports, rate limits, posts, records, and auth",
    {skip: !hasEmulators},
    async () => {
      const uid = `delete-user-${Date.now()}`;
      const authentication = getAdminAuth();
      await authentication.createUser({uid});
      await database.collection("users").doc(uid).set({nickname: "delete-me"});
      await database.collection("users").doc(uid)
          .collection("records").doc("record").set({text: "private"});
      await createPost("delete-owned", uid);
      await database.collection("contentReports").doc("delete-owned-report")
          .set({ownerId: uid, reporterId: "other"});
      await database.collection("contentReports").doc("delete-submitted-report")
          .set({ownerId: "other", reporterId: uid});
      await database.collection("reportRateLimits").doc(uid).set({count: 1});

      await deleteAccountData({database, authentication, uid});

      const remaining = await Promise.all([
        database.collection("users").doc(uid).get(),
        database.collection("sharedPosts").doc("delete-owned").get(),
        database.collection("contentReports").doc("delete-owned-report").get(),
        database.collection("contentReports")
            .doc("delete-submitted-report").get(),
        database.collection("reportRateLimits").doc(uid).get(),
      ]);
      assert.ok(remaining.every((snapshot) => !snapshot.exists));
      await assert.rejects(
          authentication.getUser(uid),
          (error) => error.code === "auth/user-not-found",
      );
    },
);

test(
    "legacy migration preserves an existing report and queues missing reports",
    {skip: !hasEmulators},
    async () => {
      const postId = `migration-race-${Date.now()}`;
      const existingReporter = "existing-reporter";
      const missingReporter = "missing-reporter";
      await createPost(postId);
      const postReference = database.collection("sharedPosts").doc(postId);
      await postReference.update({
        reportedBy: [existingReporter, missingReporter],
        reportCount: 2,
      });
      const existingReference = database.collection("contentReports").doc(
          reportDocumentId(postId, existingReporter),
      );
      await existingReference.set({
        postId,
        ownerId: "owner",
        reporterId: existingReporter,
        reason: "harassment",
        status: "pending",
        deadlineAt: Timestamp.now(),
      });

      const migratedCount = await migratePost(database, postReference);
      const existing = await existingReference.get();
      const migrated = await database.collection("contentReports").doc(
          reportDocumentId(postId, missingReporter),
      ).get();

      assert.equal(migratedCount, 1);
      assert.equal(existing.data().reason, "harassment");
      assert.equal(existing.data().status, "pending");
      assert.equal(migrated.data().reason, "legacy_unspecified");
      assert.equal(migrated.data().status, "pending");
      assert.ok(migrated.data().deadlineAt);
    },
);
