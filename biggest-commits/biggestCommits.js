// This script queries the GH API to return all
// commits from a given repo that add more than
// 100 lines.

// Expected arguments: a GH personal access token,
// the GH username of the person who's repo we're
// checking, and the name of the repo. The personal
// access token can be created here:
// https://github.com/settings/tokens

const https = require('https')

const token = process.argv[2]
const owner = process.argv[3]
const repo = process.argv[4]

let commits = ''
const commitsBySHA = {}

// recieves an index of all commits on the target repo
// from GH API and triggers `getStats` for each commit
const commitIndexHandler = res => {
  res.on('data', d => {
    commits += d.toString()
  })
  res.on('end', () => {
    const commitsObj = JSON.parse(commits)
    commitsObj.forEach(c => {
      commitsBySHA[c.sha] = {}
      getStats(c.sha)
    })
  })
  res.on('error', console.error)
}

// recieves metadata for one commit from GH API and
// pushes it to the `commitsBySHA` object
const statsHandler = res => {
  let resStr = ''
  res.on('data', d => {
    resStr += d.toString()
  })
  res.on('end', () => {
    const data = JSON.parse(resStr)
    commitsBySHA[data.sha].additions = data.stats.additions
    commitsBySHA[data.sha].deletions = data.stats.deletions
    commitsBySHA[data.sha].filesChanged = data.files.length
    commitsBySHA[data.sha].message = data.commit.message
  })
}

// initial API request to get a list of all commits
https.get({
  host: 'api.github.com',
  path: `https://api.github.com/repos/${owner}/${repo}/commits?access_token=${token}`,
  headers: {
    'User-Agent': 'ga-wdi-bos'
  }
}, commitIndexHandler)

// wait 1000ms for `commitsBySHA` to be populated then
// print the data we've gathered.
// Yes, I know this is inelegant.
setTimeout(function () {
  console.log('Commits that add more than 100 lines: \n')
  let foundLongCommit = false
  Object.keys(commitsBySHA).forEach((c) => {
    if (commitsBySHA[c].additions > 100) {
      foundLongCommit = true
      console.log(c)
      console.log('Lines added: ', commitsBySHA[c].additions)
      console.log('Files changed: ', commitsBySHA[c].filesChanged)
      console.log('Message: ', commitsBySHA[c].message.split('\n')[0], '\n')
    }
  })
  if (!foundLongCommit) {
    console.log('None!')
  }
}, 1000)

// function to trigger API request for commit metadata from one commit
const getStats = sha => {
  https.get({
    host: 'api.github.com',
    path: `https://api.github.com/repos/${owner}/${repo}/commits/${sha}?access_token=${token}`,
    headers: {
      'User-Agent': 'ga-wdi-bos'
    }
  }, statsHandler)
}
