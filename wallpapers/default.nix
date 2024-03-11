{ fetchgit
,
}:
fetchgit {
  url = "https://github.com/treyfortmuller/wallpapers.git";
  branchName = "master";
  sha256 = "sha256-KMDdgGo3CuOkp7D3hx37wP+ijIJ76NmiDODOQwmN5yU=";

  # Wallpapers in this repo are all tracked with LFS
  fetchLFS = true;
}
