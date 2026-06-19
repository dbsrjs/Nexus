/**
 * Read-only view of a synced GitLab repository (gitlab_repos row).
 * Shape returned by GET /api/gitlab/repos.
 */
export class GitlabRepoDto {
  id!: string;
  gitlabProjectId!: string;
  name!: string;
  path!: string;
  defaultBranch!: string | null;
  lastCommitMsg!: string | null;
  syncedAt!: Date;
  kind!: string | null;
}
