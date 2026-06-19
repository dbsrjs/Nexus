/**
 * Result of a manual sync trigger (POST /api/gitlab/sync).
 * `synced` is the number of repos upserted; `skipped` is true when no
 * GITLAB_TOKEN is configured (sync is a graceful no-op in that case).
 */
export class GitlabSyncResultDto {
  synced!: number;
  skipped!: boolean;
  message!: string;
}
