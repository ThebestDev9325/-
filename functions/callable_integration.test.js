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
  signInWithCustomToken,
} = require("firebase/auth");
const {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} = require("firebase/functions");
const {deleteAccountData} = require("./account_deletion");
const {resolveContentReport} = require("./content_report_resolution");
const {
  legacyReportDocumentId,
} = require("./content_report_identity");

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
  const credential = await signInAnonymously(auth);
  const functions = getFunctions(app, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  return {
    app,
    userId: credential.user.uid,
    publish: httpsCallable(functions, "publishSharedRecord"),
    report: httpsCallable(functions, "reportSharedPost"),
  };
}

async function createConnectedPublisher(name) {
  const userId = `kakao:${name}-${Date.now()}`;
  const authentication = getAdminAuth();
  await authentication.createUser({uid: userId});
  const app = initializeApp(
      {projectId, apiKey: "demo-api-key"},
      `publisher-${name}-${Date.now()}`,
  );
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", {
    disableWarnings: true,
  });
  const customToken = await authentication.createCustomToken(
      userId,
      {provider: "kakao"},
  );
  await signInWithCustomToken(auth, customToken);
  const functions = getFunctions(app, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  return {
    app,
    userId,
    publish: httpsCallable(functions, "publishSharedRecord"),
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
  clientUserId = `kakao:test-${Date.now()}`;
  const authentication = getAdminAuth();
  await authentication.createUser({uid: clientUserId});
  const customToken = await authentication.createCustomToken(
      clientUserId,
      {provider: "kakao"},
  );
  await signInWithCustomToken(auth, customToken);
  const functions = getFunctions(clientApp, "asia-northeast3");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);
  publishSharedRecord = httpsCallable(functions, "publishSharedRecord");
  reportSharedPost = httpsCallable(functions, "reportSharedPost");
});

test.after(async () => {
  if (clientApp) await deleteApp(clientApp);
  if (clientUserId) await getAdminAuth().deleteUser(clientUserId);
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
      assert.equal(Object.hasOwn(post.data(), "reportedBy"), false);
      assert.equal(record.data().shared, true);
    },
);

test(
    "anonymous authentication cannot publish to the shared feed",
    {skip: !hasEmulators},
    async () => {
      const reporter = await createAnonymousReporter("publish");
      const recordId = `anonymous-publish-${Date.now()}`;
      await database.collection("users").doc(reporter.userId)
          .collection("records").doc(recordId).set({
            ownerId: reporter.userId,
            createdAt: Timestamp.now(),
            category: "직장",
            moodEmoji: "😤",
            moodLabel: "많이 화남",
            text: "익명 계정으로 공유를 시도합니다.",
            storyId: recordId,
            shared: false,
          });

      try {
        await assert.rejects(
            reporter.publish({recordId}),
            (error) => error.code === "functions/permission-denied",
        );
        const post = await database.collection("sharedPosts")
            .doc(recordId).get();
        assert.equal(post.exists, false);
      } finally {
        await deleteApp(reporter.app);
      }
    },
);

test(
    "callables reject requests without Firebase authentication",
    {skip: !hasEmulators},
    async () => {
      const app = initializeApp(
          {projectId, apiKey: "demo-api-key"},
          `unauthenticated-${Date.now()}`,
      );
      const functions = getFunctions(app, "asia-northeast3");
      connectFunctionsEmulator(functions, "127.0.0.1", 5001);

      try {
        await assert.rejects(
            httpsCallable(functions, "publishSharedRecord")({
              recordId: "unauthenticated-record",
            }),
            (error) => error.code === "functions/unauthenticated",
        );
        await assert.rejects(
            httpsCallable(functions, "reportSharedPost")({
              postId: "unauthenticated-post",
              reason: "spam",
            }),
            (error) => error.code === "functions/unauthenticated",
        );
      } finally {
        await deleteApp(app);
      }
    },
);

test(
    "a connected user cannot overwrite another owner's post",
    {skip: !hasEmulators},
    async () => {
      const publisher = await createConnectedPublisher("collision");
      const recordId = `publish-collision-${Date.now()}`;
      const postReference = database.collection("sharedPosts").doc(recordId);
      await createPost(recordId, "victim-owner");
      await database.collection("users").doc(publisher.userId)
          .collection("records").doc(recordId).set({
            ownerId: publisher.userId,
            createdAt: Timestamp.now(),
            category: "직장",
            moodEmoji: "😤",
            moodLabel: "많이 화남",
            text: "다른 사용자의 게시물을 덮어쓰려는 기록입니다.",
            storyId: recordId,
            shared: false,
          });

      try {
        await assert.rejects(
            publisher.publish({recordId}),
            (error) => error.code === "functions/already-exists",
        );
        const post = await postReference.get();
        assert.equal(post.data().ownerId, "victim-owner");
        assert.equal(post.data().text, "오늘 회사에서 속상한 일이 있었어요.");
      } finally {
        await deleteApp(publisher.app);
        await getAdminAuth().deleteUser(publisher.userId);
      }
    },
);

test(
    "publishing canonicalizes a spoofed private owner to the authenticated user",
    {skip: !hasEmulators},
    async () => {
      const recordId = `publish-owner-spoof-${Date.now()}`;
      const recordReference = database.collection("users").doc(clientUserId)
          .collection("records").doc(recordId);
      await recordReference.set({
        ownerId: "victim-owner",
        createdAt: Timestamp.now(),
        category: "직장",
        moodEmoji: "😤",
        moodLabel: "많이 화남",
        text: "다른 사용자를 작성자로 위조하려는 기록입니다.",
        storyId: recordId,
        shared: false,
      });

      const result = await publishSharedRecord({recordId});
      const post = await database.collection("sharedPosts").doc(recordId).get();
      const record = await recordReference.get();

      assert.equal(result.data.published, true);
      assert.equal(post.data().ownerId, clientUserId);
      assert.equal(record.data().shared, true);
    },
);

test(
    "re-publishing an owned post preserves moderation and reaction state",
    {skip: !hasEmulators},
    async () => {
      const recordId = `publish-idempotent-${Date.now()}`;
      const recordReference = database.collection("users").doc(clientUserId)
          .collection("records").doc(recordId);
      const postReference = database.collection("sharedPosts").doc(recordId);
      await recordReference.set({
        ownerId: clientUserId,
        createdAt: Timestamp.now(),
        category: "직장",
        moodEmoji: "😤",
        moodLabel: "많이 화남",
        text: "재시도해도 공개 상태가 보존되어야 합니다.",
        storyId: recordId,
        shared: false,
      });
      await publishSharedRecord({recordId});
      await postReference.update({
        reactions: [1, 0, 0],
        reactedBy: ["reactor"],
        reportCount: 1,
        reportedBy: ["reporter"],
      });

      const result = await publishSharedRecord({recordId});
      const post = await postReference.get();

      assert.equal(result.data.published, true);
      assert.deepEqual(post.data().reactions, [1, 0, 0]);
      assert.deepEqual(post.data().reactedBy, ["reactor"]);
      assert.equal(post.data().reportCount, 1);
      assert.deepEqual(post.data().reportedBy, ["reporter"]);
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
      const suspension = await database.collection("moderationSuspensions")
          .doc(ownerId).get();
      const owner = await authentication.getUser(ownerId);

      assert.equal(result.resolvedCount, 2);
      assert.equal(post.exists, false);
      assert.equal(record.data().shared, false);
      assert.equal(suspension.data().status, "suspended");
      assert.equal(suspension.data().postId, postId);
      assert.ok(reports.every((report) => report.data().status === "resolved"));
      assert.ok(reports.every((report) => report.data().resolvedAt));
      assert.equal(owner.disabled, true);
      await authentication.deleteUser(ownerId);
    },
);

test(
    "moderation does not consume reports or posts from a reused post id",
    {skip: !hasEmulators},
    async () => {
      const reportedOwnerId = `reported-owner-${Date.now()}`;
      const currentOwnerId = `current-owner-${Date.now()}`;
      const postId = `reused-post-${Date.now()}`;
      const authentication = getAdminAuth();
      await authentication.createUser({uid: reportedOwnerId});
      await createPost(postId, currentOwnerId);
      await database.collection("users").doc(currentOwnerId)
          .collection("records").doc(postId).set({shared: true});
      const reportedOwnerReport = database.collection("contentReports")
          .doc(`${postId}-reported-owner`);
      const currentOwnerReport = database.collection("contentReports")
          .doc(`${postId}-current-owner`);
      await Promise.all([
        reportedOwnerReport.set({
          postId,
          ownerId: reportedOwnerId,
          reporterId: "first-reporter",
          status: "pending",
          deadlineAt: Timestamp.now(),
        }),
        currentOwnerReport.set({
          postId,
          ownerId: currentOwnerId,
          reporterId: "second-reporter",
          status: "pending",
          deadlineAt: Timestamp.now(),
        }),
      ]);

      const result = await resolveContentReport({
        database,
        authentication,
        reportId: reportedOwnerReport.id,
        action: "remove-and-suspend",
        actionedBy: "moderator@example.com",
      });
      const [oldReport, currentReport, currentPost, currentRecord] =
          await Promise.all([
            reportedOwnerReport.get(),
            currentOwnerReport.get(),
            database.collection("sharedPosts").doc(postId).get(),
            database.collection("users").doc(currentOwnerId)
                .collection("records").doc(postId).get(),
          ]);

      assert.equal(result.resolvedCount, 1);
      assert.equal(oldReport.data().status, "resolved");
      assert.equal(currentReport.data().status, "pending");
      assert.equal(currentPost.data().ownerId, currentOwnerId);
      assert.equal(currentRecord.data().shared, true);
      assert.equal(
          (await authentication.getUser(reportedOwnerId)).disabled,
          true,
      );
      await authentication.deleteUser(reportedOwnerId);
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
      const suspension = await database.collection("moderationSuspensions")
          .doc(ownerId).get();

      assert.ok(
          reports.every(
              (report) => report.data().status === "action_required",
          ),
      );
      assert.ok(reports.every((report) => report.data().suspensionError));
      assert.equal(suspension.data().status, "suspended");
    },
);

test(
    "reject leaves reports awaiting suspension retry untouched",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `reject-guard-owner-${Date.now()}`;
      const postId = `reject-guard-post-${Date.now()}`;
      await createPost(postId, ownerId);
      const reportReference = database.collection("contentReports")
          .doc(`${postId}-report`);
      await reportReference.set({
        postId,
        ownerId,
        reporterId: "reporter",
        status: "action_required",
        resolution: "post_removed_user_suspension_failed",
        suspensionError: "temporary auth failure",
        deadlineAt: Timestamp.now(),
      });

      const result = await resolveContentReport({
        database,
        authentication: getAdminAuth(),
        reportId: reportReference.id,
        action: "reject",
        actionedBy: "moderator@example.com",
      });
      const report = await reportReference.get();

      assert.equal(result.resolvedCount, 0);
      assert.equal(report.data().status, "action_required");
      assert.equal(
          report.data().resolution,
          "post_removed_user_suspension_failed",
      );
    },
);

test(
    "reject leaves reports mid removal untouched",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `reject-midway-owner-${Date.now()}`;
      const postId = `reject-midway-post-${Date.now()}`;
      await createPost(postId, ownerId);
      const reportReference = database.collection("contentReports")
          .doc(`${postId}-report`);
      await reportReference.set({
        postId,
        ownerId,
        reporterId: "reporter",
        status: "action_pending",
        resolution: "post_removal_and_user_suspension_pending",
        deadlineAt: Timestamp.now(),
      });

      const result = await resolveContentReport({
        database,
        authentication: getAdminAuth(),
        reportId: reportReference.id,
        action: "reject",
        actionedBy: "moderator@example.com",
      });
      const report = await reportReference.get();

      assert.equal(result.resolvedCount, 0);
      assert.equal(report.data().status, "action_pending");
      assert.equal(
          report.data().resolution,
          "post_removal_and_user_suspension_pending",
      );
    },
);

test(
    "reject records only pending reports as no violation",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `reject-pending-owner-${Date.now()}`;
      const postId = `reject-pending-post-${Date.now()}`;
      await createPost(postId, ownerId);
      const reportReference = database.collection("contentReports")
          .doc(`${postId}-report`);
      await reportReference.set({
        postId,
        ownerId,
        reporterId: "reporter",
        status: "pending",
        deadlineAt: Timestamp.now(),
      });

      const result = await resolveContentReport({
        database,
        authentication: getAdminAuth(),
        reportId: reportReference.id,
        action: "reject",
        actionedBy: "moderator@example.com",
      });
      const report = await reportReference.get();
      const post = await database.collection("sharedPosts").doc(postId).get();

      assert.equal(result.resolvedCount, 1);
      assert.equal(report.data().status, "rejected");
      assert.equal(report.data().resolution, "no_violation");
      assert.equal(post.exists, true);
    },
);

test(
    "reject skips a report that turns non-pending after the initial read " +
    "before the transaction re-read",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `reject-race-owner-${Date.now()}`;
      const postId = `reject-race-post-${Date.now()}`;
      await createPost(postId, ownerId);
      const reportReference = database.collection("contentReports")
          .doc(`${postId}-report`);
      await reportReference.set({
        postId,
        ownerId,
        reporterId: "reporter",
        status: "pending",
        deadlineAt: Timestamp.now(),
      });

      // reportGroup이 pending을 읽은 뒤, rejectReports가 트랜잭션에서 재-get하기
      // 전에 remove-and-suspend가 상태를 action_pending으로 전이시키는 race를
      // 주입한다. 트랜잭션 재-get 구현은 현재 상태(action_pending)를 보고 skip하고,
      // 초기 snapshot을 쓰는 단순 필터 구현이면 pending으로 판정해 no_violation을
      // 덮어 이 테스트가 실패한다.
      const result = await resolveContentReport({
        database,
        authentication: getAdminAuth(),
        reportId: reportReference.id,
        action: "reject",
        actionedBy: "moderator@example.com",
        hooks: {
          beforeReject: async () => {
            await reportReference.update({
              status: "action_pending",
              resolution: "post_removal_and_user_suspension_pending",
            });
          },
        },
      });
      const report = await reportReference.get();

      assert.equal(result.resolvedCount, 0);
      assert.equal(report.data().status, "action_pending");
      assert.equal(
          report.data().resolution,
          "post_removal_and_user_suspension_pending",
      );
    },
);

test(
    "moderation handles more than one Firestore transaction of reports",
    {skip: !hasEmulators},
    async () => {
      const ownerId = `moderation-scale-owner-${Date.now()}`;
      const postId = `moderation-scale-post-${Date.now()}`;
      const authentication = getAdminAuth();
      await authentication.createUser({uid: ownerId});
      await createPost(postId, ownerId);
      const writer = database.bulkWriter();
      const reportReferences = Array.from({length: 501}, (_, index) => {
        const reference = database.collection("contentReports")
            .doc(`${postId}-report-${index}`);
        writer.set(reference, {
          postId,
          ownerId,
          reporterId: `reporter-${index}`,
          status: "pending",
          deadlineAt: Timestamp.now(),
        });
        return reference;
      });
      await writer.close();

      const result = await resolveContentReport({
        database,
        authentication,
        reportId: reportReferences[0].id,
        action: "remove-and-suspend",
        actionedBy: "moderator@example.com",
      });
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();

      assert.equal(result.resolvedCount, 501);
      assert.ok(reports.docs.every((report) => {
        return report.data().status === "resolved";
      }));
      await authentication.deleteUser(ownerId);
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
    "callable records a private report and deduplicates the same reporter",
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
      const publicPost = await database.collection("sharedPosts")
          .doc(postId).get();
      assert.equal(Object.hasOwn(publicPost.data(), "reportedBy"), false);
    },
);

test(
    "callable stores a reporter's custom reason",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-custom-reason-${Date.now()}`;
      await createPost(postId);

      await reportSharedPost({
        postId,
        reason: "other",
        detail: "욕설이 포함된 게시물입니다.",
      });
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();

      assert.equal(reports.size, 1);
      assert.equal(reports.docs[0].data().reason, "other");
      assert.equal(
          reports.docs[0].data().detail,
          "욕설이 포함된 게시물입니다.",
      );
    },
);

test(
    "a reporter can flag every objectionable post without an hourly cap",
    {skip: !hasEmulators},
    async () => {
      const prefix = `callable-no-report-cap-${Date.now()}`;
      for (let index = 0; index < 11; index++) {
        const postId = `${prefix}-${index}`;
        await createPost(postId, `owner-${index}`);
        const result = await reportSharedPost({
          postId,
          ownerId: `owner-${index}`,
          reason: "harassment",
        });
        assert.equal(result.data.alreadyReported, false);
      }
      const reports = await database.collection("contentReports")
          .get();
      assert.equal(
          reports.docs.filter((report) => {
            return report.data().postId.startsWith(prefix);
          }).length,
          11,
      );
    },
);

test(
    "a stale owner id cannot report a replacement post",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-stale-owner-${Date.now()}`;
      await createPost(postId, "original-owner");
      await database.collection("sharedPosts").doc(postId).delete();
      await createPost(postId, "replacement-owner");

      const result = await reportSharedPost({
        postId,
        ownerId: "original-owner",
        reason: "spam",
      });
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();
      const replacement = await database.collection("sharedPosts")
          .doc(postId).get();

      assert.equal(result.data.removed, true);
      assert.equal(result.data.alreadyReported, false);
      assert.equal(reports.size, 0);
      assert.equal(replacement.data().reportCount, 0);
    },
);

test(
    "the same reporter can report a reused post id owned by another user",
    {skip: !hasEmulators},
    async () => {
      const postId = `callable-reused-${Date.now()}`;
      await createPost(postId, "first-owner");
      await reportSharedPost({postId, reason: "harassment"});
      await database.collection("sharedPosts").doc(postId).delete();
      await createPost(postId, "second-owner");

      const second = await reportSharedPost({postId, reason: "spam"});
      const reports = await database.collection("contentReports")
          .where("postId", "==", postId)
          .get();
      const currentPost = await database.collection("sharedPosts")
          .doc(postId).get();

      assert.equal(second.data.alreadyReported, false);
      assert.equal(second.data.reportCount, 1);
      assert.equal(reports.size, 2);
      assert.deepEqual(
          new Set(reports.docs.map((report) => report.data().ownerId)),
          new Set(["first-owner", "second-owner"]),
      );
      assert.equal(currentPost.data().reportCount, 1);
    },
);

test(
    "suspended users cannot publish or report with an existing session",
    {skip: !hasEmulators},
    async () => {
      const publisher = await createConnectedPublisher("suspended");
      const reporter = await createAnonymousReporter("suspended");
      const recordId = `suspended-publish-${Date.now()}`;
      const postId = `suspended-report-${Date.now()}`;
      await database.collection("users").doc(publisher.userId)
          .collection("records").doc(recordId).set({
            ownerId: publisher.userId,
            createdAt: Timestamp.now(),
            category: "직장",
            moodEmoji: "😤",
            moodLabel: "많이 화남",
            text: "오늘 회사에서 속상한 일이 있었어요.",
            storyId: recordId,
            shared: false,
          });
      await createPost(postId);
      await Promise.all([
        database.collection("moderationSuspensions")
            .doc(publisher.userId).set({status: "suspended"}),
        database.collection("moderationSuspensions")
            .doc(reporter.userId).set({status: "suspended"}),
      ]);

      try {
        await assert.rejects(
            publisher.publish({recordId}),
            (error) => error.code === "functions/permission-denied",
        );
        await assert.rejects(
            reporter.report({postId, reason: "spam"}),
            (error) => error.code === "functions/permission-denied",
        );
        const [post, record] = await Promise.all([
          database.collection("sharedPosts").doc(postId).get(),
          database.collection("users").doc(publisher.userId)
              .collection("records").doc(recordId).get(),
        ]);
        assert.equal(post.data().reportCount, 0);
        assert.equal(record.data().shared, false);
      } finally {
        await Promise.all([
          deleteApp(publisher.app),
          deleteApp(reporter.app),
          getAdminAuth().deleteUser(publisher.userId),
        ]);
      }
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
      const publicPost = await database.collection("sharedPosts")
          .doc(postId).get();
      assert.deepEqual(publicPost.data().reportedBy, []);
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
    "account deletion removes reports, posts, records, and auth",
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
      await createPost("delete-observed", "other-owner");
      await database.collection("sharedPosts").doc("delete-observed").update({
        reportedBy: [uid, "other-reporter"],
        reactedBy: [uid, "other-reactor"],
        reportCount: 2,
        reactions: [2, 0, 0],
      });

      await deleteAccountData({database, authentication, uid});

      const remaining = await Promise.all([
        database.collection("users").doc(uid).get(),
        database.collection("sharedPosts").doc("delete-owned").get(),
        database.collection("contentReports").doc("delete-owned-report").get(),
        database.collection("contentReports")
            .doc("delete-submitted-report").get(),
        database.collection("sharedPosts").doc("delete-observed").get(),
      ]);
      assert.ok(remaining.slice(0, -1).every((snapshot) => !snapshot.exists));
      assert.deepEqual(
          remaining.at(-1).data().reportedBy,
          ["other-reporter"],
      );
      assert.deepEqual(
          remaining.at(-1).data().reactedBy,
          ["other-reactor"],
      );
      await assert.rejects(
          authentication.getUser(uid),
          (error) => error.code === "auth/user-not-found",
      );
    },
);
