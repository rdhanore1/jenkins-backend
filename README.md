# Jenkins Backend — CI/CD & Deployment

This document describes the recommended CI/CD pipeline and deployment process for the jenkins-backend repository. It covers Jenkins pipeline configuration, build and test steps, containerization, artifact registry, and deployment to environments (staging/production).

## Overview

Goals:
- Provide a repeatable CI pipeline that builds, tests, scans, and packages the service.
- Publish build artifacts (Docker images) to a registry.
- Deploy to staging automatically and provide a safe promotion path to production.
- Integrate security scanning and notifications.

Intended audience: Maintainers, DevOps engineers, and reviewers working on CI/CD for this repository.

---

## Prerequisites

- Jenkins (LTS) with these plugins installed:
  - Pipeline (workflow-aggregator)
  - Docker Pipeline
  - GitHub Branch Source / GitHub Integration
  - Credentials Binding
  - Blue Ocean (optional)
  - Role-based Authorization (if you need RBAC in Jenkins)
  - Pipeline Utility Steps
  - Static Analysis / Security scanning plugins (optional)
- A Docker registry (Docker Hub, GitHub Packages, ECR, GCR, etc.) and a credentials entry in Jenkins.
- kubectl and/or Helm access to target clusters, or another deployment mechanism.
- Webhook from GitHub to Jenkins or Multibranch Pipeline configured.

---

## Environment & Credentials

Create Jenkins credentials (Credentials -> System -> Global credentials):
- DOCKER_REGISTRY_CREDENTIALS (username/password or token)
- KUBECONFIG (file or secret text) or use cluster-specific credentials
- GIT_CREDENTIALS (if private repository access is needed)
- NOTIFY_SLACK (optional webhook URL credential)

Use credential IDs (above) in the pipeline environment.

---

## CI/CD Pipeline Design

Recommended pipeline stages:
1. Checkout
2. Build
3. Unit tests
4. Lint / Static analysis
5. Security scans (SCA/SAST)
6. Package (build Docker image)
7. Push image to registry (tagged by build number, commit SHA, branch)
8. Deploy to staging
9. Integration/E2E tests on staging
10. Manual approval to promote to production
11. Deploy to production

Keep pipeline declarative and idempotent. Fail fast on tests or scans.

---

## Example Jenkinsfile (Declarative)

Below is a sample Declarative Jenkinsfile that implements the pipeline. Adapt stages, tools, image names and commands to your project.

```groovy
pipeline {
  agent any

  environment {
    REGISTRY_URL = 'registry.example.com/rdhanore1/jenkins-backend'
    DOCKER_CREDENTIALS = 'DOCKER_REGISTRY_CREDENTIALS'
    KUBE_CREDENTIALS = 'KUBECONFIG'
    IMAGE_TAG = "${env.BRANCH_NAME ==~ /main|master/ ? 'latest' : env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,7)}"
  }

  options {
    skipStagesAfterUnstable()
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh './gradlew clean assemble --no-daemon' // or `mvn -B -DskipTests package`
      }
    }

    stage('Unit Tests') {
      steps {
        sh './gradlew test --no-daemon'
        junit 'build/test-results/**/*.xml'
      }
    }

    stage('Lint & Static Analysis') {
      steps {
        // Example: run linter
        sh './gradlew check --no-daemon'
      }
    }

    stage('Security Scan') {
      steps {
        // run security scanning tools here (Snyk/Trivy/OWASP Dependency-Check)
        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL . || true'
      }
    }

    stage('Build & Push Image') {
      steps {
        script {
          docker.withRegistry("https://${env.REGISTRY_URL}", env.DOCKER_CREDENTIALS) {
            def img = docker.build("${env.REGISTRY_URL}:${env.IMAGE_TAG}")
            img.push()
            sh "docker rmi ${env.REGISTRY_URL}:${env.IMAGE_TAG} || true"
          }
        }
      }
    }

    stage('Deploy to Staging') {
      steps {
        withCredentials([file(credentialsId: env.KUBE_CREDENTIALS, variable: 'KUBECONFIG')]) {
          sh 'kubectl --kubeconfig=$KUBECONFIG set image deployment/jenkins-backend jenkins-backend=${REGISTRY_URL}:${IMAGE_TAG} -n staging'
        }
      }
    }

    stage('Integration Tests') {
      steps {
        // run integration tests against staging
        sh './scripts/integration-tests.sh'
      }
    }

    stage('Manual Approval to Prod') {
      when {
        branch 'main'
      }
      steps {
        input message: 'Promote to production?', ok: 'Deploy'
      }
    }

    stage('Deploy to Production') {
      when { branch 'main' }
      steps {
        withCredentials([file(credentialsId: env.KUBE_CREDENTIALS, variable: 'KUBECONFIG')]) {
          sh 'kubectl --kubeconfig=$KUBECONFIG set image deployment/jenkins-backend jenkins-backend=${REGISTRY_URL}:${IMAGE_TAG} -n production'
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed.'
      // Optionally notify Slack/email
    }
  }
}
```

Notes:
- Replace build commands with the language-specific build (npm, mvn, go, etc.).
- Adjust deployment commands for Helm or other orchestrators.

---

## Tagging & Image Naming

- Use semantic tags where appropriate (vX.Y.Z) and include commit SHA for traceability.
- Example tags: v1.2.3, 1234abcd, main-1234

---

## Deployment Strategies

- Blue/Green or Canary deployments recommended for production-critical services.
- Use Kubernetes rollout features, readiness/liveness probes, and health checks to ensure safe deployments.
- Keep migration and schema changes backward compatible or coordinate release windows.

---

## Rollback Plan

- Kubernetes: kubectl rollout undo deployment/jenkins-backend -n production
- Docker image rollback: redeploy a previous image tag
- Ensure you have monitoring and alerts to detect regressions quickly.

---

## Security and Scanning

- Integrate SCA (e.g., Snyk, Dependabot) and container image scanning (Trivy, Clair).
- Fail builds or raise warnings on critical vulnerabilities.
- Keep secrets out of the repository; use Jenkins credentials, Vault, or Kubernetes Secrets.

---

## Notifications

- Configure post-build notifications to Slack, email, or other channels.
- Include build URL, commit, author, and a short summary in notifications.

---

## Troubleshooting

- Common Jenkins issues: workspace disk space, agent connectivity, credential permissions.
- Use Blue Ocean or pipeline logs for step-level troubleshooting.
- Reproduce locally via the same Docker build commands.

---

## Contributing

- Update the Jenkinsfile if you change build or deployment steps.
- Add integration tests to the scripts/integration-tests.sh path and ensure they run in CI.
- Document any new environment variables or credentials in this README.

---

## Appendix: Quick local Docker build & push

```sh
# Build locally
docker build -t registry.example.com/rdhanore1/jenkins-backend:local-$(git rev-parse --short HEAD) .
# Push
docker login registry.example.com
docker push registry.example.com/rdhanore1/jenkins-backend:local-$(git rev-parse --short HEAD)
```