# Path to your local GitHub repository
$repoPath = "."

# Get a list of JSON files in the current directory
$jsonFiles = Get-ChildItem -Path "./commit-data" -Filter "*.json"

# Initialize the Git repository
cd $repoPath
git init

# Define a list to store all commit data
$allCommits = @()

# Iterate over each JSON file
foreach ($jsonFile in $jsonFiles) {
    # Read JSON data from the file
    $jsonData = Get-Content -Raw -Path $jsonFile.FullName | ConvertFrom-Json

    # Get the filename without the .json extension
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile.Name)

    # Iterate over commit data and store in $allCommits
    $jsonData.values | ForEach-Object {
        $commit = [PSCustomObject]@{
            AuthorName       = $_.author.displayName
            AuthorEmail      = $_.author.emailAddress
            CommitterName    = $_.committer.displayName
            CommitterEmail   = $_.committer.emailAddress
            AuthorTimestamp  = [DateTimeOffset]::FromUnixTimeMilliseconds($_.authorTimestamp).UtcDateTime
            CommitterTimestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($_.committerTimestamp).UtcDateTime
            Message          = "$fileName - " + $_.message
        }
        $allCommits += $commit
    }
}

# Sort all commits by CommitterTimestamp in ascending order
$sortedCommits = $allCommits | Sort-Object CommitterTimestamp

# Get existing commit committer dates in the format yyyy-MM-dd HH:mm:ss
$existingCommitterDates = git log --pretty=format:"%cd" --date=format:"%Y-%m-%d %H:%M:%S"

# Iterate over the sorted commits and create the commits in Git
foreach ($commit in $sortedCommits) {
    $commitMessage = $commit.Message.Replace('"', '""') # Escape double quotes in the commit message
    $committerDateFormatted = $commit.CommitterTimestamp.ToString("yyyy-MM-dd HH:mm:ss")

    # Check if the committer date already exists
    if ($existingCommitterDates -notcontains $committerDateFormatted) {
        # Set the author and committer
        git config user.name $commit.AuthorName
        git config user.email {param1}

        # Set the author and committer dates
        $env:GIT_AUTHOR_DATE = $commit.AuthorTimestamp.ToString("yyyy-MM-dd HH:mm:ss")
        $env:GIT_COMMITTER_DATE = $committerDateFormatted

        # Create the commit
        git commit --allow-empty -m "$commitMessage"
    } else {
        Write-Host "Skipping existing commit: $commitMessage with committer date $committerDateFormatted"
    }
}