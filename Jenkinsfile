pipeline {
  agent any
  stages {
    stage('Git Checout') {
      steps {
        git(url: 'https://github.com/OsamaKM/sample-react-app', branch: 'main')
      }
    }

    stage('Install Dependencies') {
      steps {
        nodejs 'npm install'
      }
    }

  }
}