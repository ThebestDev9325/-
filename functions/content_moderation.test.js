const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const {
  findContentViolation,
  isValidSharedPost,
} = require("./content_moderation");

const fixturePath = path.join(
    __dirname,
    "..",
    "test",
    "fixtures",
    "community_moderation_cases.json",
);
const cases = JSON.parse(fs.readFileSync(fixturePath, "utf8"));

for (const testCase of cases) {
  test(testCase.name, () => {
    assert.equal(findContentViolation(testCase), testCase.expected);
  });
}

function validSharedPost() {
  return {
    ownerId: "owner",
    createdAt: {toMillis: () => 1785196800000},
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

test("server accepts the same initial post contract as Firestore", () => {
  assert.equal(isValidSharedPost(validSharedPost()), true);
});

test("server rejects oversized text and pre-populated counters", () => {
  assert.equal(
      isValidSharedPost({...validSharedPost(), text: "가".repeat(2001)}),
      false,
  );
  assert.equal(
      isValidSharedPost({...validSharedPost(), reactions: [1, 0, 0]}),
      false,
  );
});
