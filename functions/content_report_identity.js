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

function reporterHash(reporterId) {
  return hashIdentifier(reporterId);
}

function reportRequestDocumentId(requestId) {
  return hashIdentifier(requestId);
}

module.exports = {
  legacyReportDocumentId,
  reportDocumentId,
  reportRequestDocumentId,
  reporterHash,
};
