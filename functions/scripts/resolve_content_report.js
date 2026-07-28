const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {resolveContentReport} = require("../content_report_resolution");

initializeApp({credential: applicationDefault()});
const database = getFirestore();

const allowedActions = new Set(["remove-and-suspend", "reject"]);
const actionedBy = process.env.MODERATOR_EMAIL || "a01041989325@gmail.com";

async function main() {
  const [reportId, action] = process.argv.slice(2);
  if (!reportId || !allowedActions.has(action)) {
    process.stderr.write(
        "Usage: node scripts/resolve_content_report.js <reportId> " +
        "<remove-and-suspend|reject>\n",
    );
    process.exitCode = 2;
    return;
  }
  const result = await resolveContentReport({
    database,
    authentication: getAuth(),
    reportId,
    action,
    actionedBy,
  });
  if (result.resolvedCount === 0) {
    process.stdout.write(`No actionable reports remain for ${result.postId}.\n`);
    return;
  }
  if (action === "reject") {
    process.stdout.write(
        `Rejected ${result.resolvedCount} reports for ${result.postId}.\n`,
    );
    return;
  }
  process.stdout.write(
      `Resolved ${result.resolvedCount} reports and suspended ` +
      `${result.ownerId}.\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error}\n`);
  process.exitCode = 1;
});
