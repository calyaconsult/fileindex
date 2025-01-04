const fs = require("fs");
const path = require("path");

// Server's DocumentRoot
const documentRoot = "C:\\Users\\User1\\Documents";

// Transform paths in the JSON
function transformPaths(jsonData, documentRoot) {
  const transformedData = [];
  // Normalize the document root for consistent path operations
  const normalizedRoot = path.normalize(documentRoot);
  console.log(normalizedRoot, documentRoot);

  // Update fileinfo entries
  if (Array.isArray(jsonData.fileinfo)) {
    jsonData.fileinfo
      .filter((x) => x.extension === ".html")
      .forEach((entry) => {
        if (entry.directory) {
          entry.directory = entry.directory
            .replace(`${documentRoot}\\`, "")
            .replace(/\\/g, "/");
        }
        if (entry.relative_path) {
          entry.relative_path = entry.relative_path.replace(/\\/g, "/");
        }
        transformedData.push(entry);
      });
  }
  jsonData.fileinfo = transformedData;
  return jsonData;
}

// Input and output file paths
const inputFile = "file_index.json";
const outputFile = "output.json";

// Read, transform, and save the JSON file
fs.readFile(inputFile, "utf-8", (err, data) => {
  if (err) {
    console.error("Error reading the input file:", err);
    return;
  }

  try {
    const jsonData = JSON.parse(data);
    const updatedJson = transformPaths(jsonData, documentRoot);

    fs.writeFile(
      outputFile,
      JSON.stringify(updatedJson, null, 4),
      "utf-8",
      (err) => {
        if (err) {
          console.error("Error writing the output file:", err);
        } else {
          console.log(`Updated JSON saved to ${outputFile}`);
        }
      },
    );
  } catch (parseError) {
    console.error("Error parsing the JSON file:", parseError);
  }
});
