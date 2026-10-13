const releaseAPI = "https://api.github.com/repos/inthiiii/stickyy/releases/latest";
const downloadButton = document.querySelector("#download-button");
const downloadLabel = document.querySelector("#download-label");
const releaseStatus = document.querySelector("#release-status");
const mirrorDownload = document.querySelector(".mirror-download");

const formatSize = (bytes) => `${(bytes / 1_000_000).toFixed(1)} MB`;

fetch(releaseAPI, { headers: { Accept: "application/vnd.github+json" } })
  .then((response) => {
    if (!response.ok) throw new Error("No public release yet");
    return response.json();
  })
  .then((release) => {
    const diskImage = release.assets.find((asset) => asset.name.toLowerCase().endsWith(".dmg"));
    if (!diskImage) throw new Error("No disk image in the latest release");

    const version = release.tag_name.replace(/^v/, "");
    downloadButton.href = diskImage.browser_download_url;
    downloadButton.setAttribute("download", "");
    downloadLabel.textContent = `Download Stickyy ${version}`;
    mirrorDownload.href = diskImage.browser_download_url;
    mirrorDownload.textContent = `Download Stickyy ${version}`;
    releaseStatus.textContent = `macOS 26 or later · ${formatSize(diskImage.size)} · Notarized direct download`;
  })
  .catch(() => {
    const releasesURL = downloadButton.dataset.releasesUrl;
    downloadButton.href = releasesURL;
    mirrorDownload.href = releasesURL;
  });
