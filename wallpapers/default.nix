{ fetchgit
,
}:
fetchgit {
  url = "https://github.com/treyfortmuller/wallpapers.git";
  branchName = "master";
  sha256 = "sha256-3Y5N18766e9YN1mMQX1kGcCrP+Hi4yI2MDo6ioZWp9E=";

  # Wallpapers in this repo are all tracked with LFS
  fetchLFS = true;
}
