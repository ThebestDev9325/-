const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  Timestamp,
  updateDoc,
} = require("firebase/firestore");

const projectId = "chameulin-rules-test";
let environment;

function validPost(ownerId = "owner") {
  return {
    ownerId,
    createdAt: Timestamp.fromDate(new Date("2026-07-28T00:00:00Z")),
    category: "직장",
    moodEmoji: "😤",
    moodLabel: "많이 화남",
    text: "오늘 회사에서 속상한 일이 있었어요.",
    storyId: "story-1",
    shared: true,
    reactions: [0, 0, 0],
    reactedBy: [],
    reportCount: 0,
  };
}

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
          path.join(__dirname, "..", "firestore.rules"),
          "utf8",
      ),
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

test.beforeEach(async () => {
  await environment.clearFirestore();
});

test("clients cannot publish directly to the shared feed", async () => {
  const firestore = environment.authenticatedContext("owner").firestore();
  await assertFails(
      setDoc(doc(firestore, "sharedPosts/post-1"), validPost()),
  );
});

test("invalid category and arbitrary fields are rejected", async () => {
  const firestore = environment.authenticatedContext("owner").firestore();
  await assertFails(
      setDoc(
          doc(firestore, "sharedPosts/post-1"),
          {...validPost(), category: "<script>", unexpected: true},
      ),
  );
});

test("mismatched mood metadata is rejected", async () => {
  const firestore = environment.authenticatedContext("owner").firestore();
  await assertFails(
      setDoc(
          doc(firestore, "sharedPosts/post-1"),
          {...validPost(), moodLabel: "답답함"},
      ),
  );
});

test("a user can add exactly one reaction only once", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
        doc(context.firestore(), "sharedPosts/post-1"),
        validPost(),
    );
  });
  const firestore = environment.authenticatedContext("viewer").firestore();
  const reference = doc(firestore, "sharedPosts/post-1");
  await assertSucceeds(
      updateDoc(reference, {reactions: [1, 0, 0], reactedBy: ["viewer"]}),
  );
  await assertFails(
      updateDoc(reference, {reactions: [2, 0, 0], reactedBy: ["viewer"]}),
  );
});

test("a moderation suspension immediately blocks every client write", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
        doc(context.firestore(), "sharedPosts/post-1"),
        validPost("owner"),
    );
    await setDoc(
        doc(context.firestore(), "moderationSuspensions/viewer"),
        {status: "suspended"},
    );
  });
  const firestore = environment.authenticatedContext("viewer").firestore();
  await assertSucceeds(getDoc(doc(firestore, "sharedPosts/post-1")));
  await assertFails(
      updateDoc(
          doc(firestore, "sharedPosts/post-1"),
          {reactions: [1, 0, 0], reactedBy: ["viewer"]},
      ),
  );
  await assertFails(
      setDoc(
          doc(firestore, "users/viewer/records/record-1"),
          {ownerId: "viewer"},
      ),
  );
  await assertFails(
      setDoc(doc(firestore, "storyFeedback/story-1"), {
        storyId: "story-1",
        likes: 1,
        unsure: 0,
        dislikes: 0,
        total: 1,
        updatedAt: Timestamp.now(),
      }),
  );
});

test("content reports are private to server operators", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "contentReports/report-1"), {
      status: "pending",
    });
  });
  const firestore = environment.authenticatedContext("viewer").firestore();
  await assertFails(getDoc(doc(firestore, "contentReports/report-1")));
  await assertFails(
      setDoc(doc(firestore, "contentReports/report-2"), {status: "pending"}),
  );
});

test("moderation suspension markers are private to server operators", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "moderationSuspensions/viewer"), {
      status: "suspended",
    });
  });
  const firestore = environment.authenticatedContext("viewer").firestore();
  await assertFails(
      getDoc(doc(firestore, "moderationSuspensions/viewer")),
  );
  await assertFails(
      setDoc(
          doc(firestore, "moderationSuspensions/other"),
          {status: "suspended"},
      ),
  );
});

test("content report request keys are private to server operators", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "contentReportRequests/request-1"), {
      postId: "post-1",
    });
  });
  const firestore = environment.authenticatedContext("viewer").firestore();
  await assertFails(
      getDoc(doc(firestore, "contentReportRequests/request-1")),
  );
  await assertFails(
      setDoc(
          doc(firestore, "contentReportRequests/request-2"),
          {postId: "post-1"},
      ),
  );
});
