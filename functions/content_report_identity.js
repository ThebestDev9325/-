const {createHash} = require("node:crypto");

function hashIdentifier(value) {
  return createHash("sha256").update(value).digest("hex");
}

function legacyReportDocumentId(postId, reporterId) {
  return `${postId}_${hashIdentifier(reporterId)}`;
}

function reportDocumentId(postId, ownerId, reporterId) {
  return `${postId}_${hashIdentifier(`${ownerId}\0${reporterId}`)}`;
}

module.exports = {
  legacyReportDocumentId,
  reportDocumentId,
};
