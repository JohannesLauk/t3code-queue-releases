const fs = require("node:fs/promises");
const path = require("node:path");

module.exports = async ({ appOutDir, packager }) => {
  const configPath = path.join(packager.getResourcesDir(appOutDir), "app-update.yml");
  let contents;
  try {
    contents = await fs.readFile(configPath, "utf8");
  } catch (error) {
    if (error?.code === "ENOENT") return;
    throw error;
  }
  const updated = contents.replace(
    /^updaterCacheDirName:.*$/m,
    "updaterCacheDirName: t3code-queue-updater",
  );
  if (updated === contents) throw new Error("Desktop updater cache name is missing.");
  await fs.writeFile(configPath, updated);
};
