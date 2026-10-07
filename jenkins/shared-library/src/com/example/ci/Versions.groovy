package com.example.ci

/** Small helper class: real business logic belongs in src/ (easy to unit test). */
class Versions implements Serializable {
    /** Build an immutable, traceable image tag: <branch>-<sha>-<build>. */
    static String imageTag(String branch, String sha, String buildNumber) {
        def safeBranch = (branch ?: 'unknown').replaceAll(/[^A-Za-z0-9._-]/, '-')
        return "${safeBranch}-${sha ?: 'nogit'}-${buildNumber}"
    }

    /** True when this branch is allowed to push images. */
    static boolean isReleaseBranch(String branch) {
        return branch in ['main', 'develop']
    }
}
