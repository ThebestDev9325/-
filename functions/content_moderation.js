const COMMUNITY_CATEGORIES = new Set([
  "직장",
  "고객",
  "가족",
  "연인",
  "친구",
  "타인",
  "나 자신",
  "기타",
]);

const COMMUNITY_MOODS = new Map([
  ["🤬", "폭발 직전"],
  ["😤", "많이 화남"],
  ["😐", "답답함"],
  ["🙂", "조금 괜찮음"],
]);

const patterns = [
  {
    name: "personal_information",
    pattern: /(?:01[016789][-\s]?\d{3,4}[-\s]?\d{4}|[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})/i,
    compact: false,
  },
  {
    name: "harassment",
    terms: ["병신", "개새끼", "씨발", "꺼져", "찐따"],
  },
  {
    name: "hate",
    terms: ["김치녀", "한남충", "틀딱", "맘충", "외노자"],
  },
  {
    name: "violence",
    terms: ["죽여버리", "죽여버릴", "칼로찌르", "폭탄테러", "패죽이"],
  },
  {
    name: "sexual",
    terms: ["야동", "성매매", "강간", "음란물"],
  },
  {
    name: "illegal",
    terms: ["마약판매", "대포통장", "불법도박", "청부살인"],
  },
  {
    name: "spam",
    terms: ["오픈채팅", "수익보장", "고수익알바", "무료체험클릭"],
  },
];

function normalizedText(text) {
  return text
      .normalize("NFKC")
      .toLowerCase()
      .replace(/[\u200B-\u200D\u2060\uFEFF]/gu, "");
}

function compactText(text) {
  return text.replace(/[\s\-_.·,!?~'"()[\]{}<>/:;@#%^&*+=|\\]+/gu, "");
}

function findContentViolation({text, category, moodEmoji, moodLabel}) {
  if (typeof text !== "string" ||
      text.trim().length === 0 ||
      !COMMUNITY_CATEGORIES.has(category) ||
      COMMUNITY_MOODS.get(moodEmoji) !== moodLabel) {
    return "invalid_metadata";
  }

  const normalized = normalizedText(text);
  const compact = compactText(normalized);
  for (const rule of patterns) {
    if (rule.pattern && rule.pattern.test(normalized)) return rule.name;
    if (rule.terms && rule.terms.some((term) => compact.includes(term))) {
      return rule.name;
    }
  }
  return null;
}

function isValidSharedPost(data) {
  if (!data || typeof data !== "object") return false;
  const allowedKeys = new Set([
    "ownerId",
    "createdAt",
    "category",
    "moodEmoji",
    "moodLabel",
    "text",
    "storyId",
    "shared",
    "reactions",
    "reactedBy",
    "reportCount",
    "reportedBy",
  ]);
  if (Object.keys(data).some((key) => !allowedKeys.has(key))) return false;
  return typeof data.ownerId === "string" &&
    data.ownerId.length > 0 &&
    data.ownerId.length <= 128 &&
    data.createdAt &&
    typeof data.createdAt.toMillis === "function" &&
    typeof data.storyId === "string" &&
    data.storyId.length > 0 &&
    data.storyId.length <= 128 &&
    typeof data.text === "string" &&
    data.text.length > 0 &&
    data.text.length <= 2000 &&
    data.shared === true &&
    Array.isArray(data.reactions) &&
    data.reactions.length === 3 &&
    data.reactions.every((value) => value === 0) &&
    Array.isArray(data.reactedBy) &&
    data.reactedBy.length === 0 &&
    data.reportCount === 0 &&
    (!("reportedBy" in data) ||
      (Array.isArray(data.reportedBy) &&
       data.reportedBy.length === 0)) &&
    findContentViolation(data) === null;
}

module.exports = {
  COMMUNITY_CATEGORIES,
  COMMUNITY_MOODS,
  findContentViolation,
  isValidSharedPost,
};
