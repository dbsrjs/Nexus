import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { GitlabRepoDto } from './dto/gitlab-repo.dto';
import { GitlabSyncResultDto } from './dto/sync-result.dto';

/** Minimal shape of the GitLab REST `GET /projects` response we consume. */
interface GitlabProject {
  id: number;
  name: string;
  path_with_namespace: string;
  default_branch?: string | null;
}

/** Minimal shape of a GitLab commit (`GET /projects/:id/repository/commits`). */
interface GitlabCommit {
  title?: string;
  message?: string;
}

/**
 * Read-only GitLab client.
 *
 * Talks to a self-hosted GitLab via REST using GITLAB_URL + GITLAB_TOKEN
 * (Personal/Project Access Token, read-only scope). It only reads — never
 * writes to GitLab — and caches the result into the `gitlab_repos` table.
 *
 * If no token is configured the client degrades gracefully: sync becomes a
 * no-op and reads simply return whatever is already cached (possibly empty).
 * Per design doc §7 the scope is repos/branches/last-commit only; code
 * embedding/analysis is deferred to the AI phase.
 */
@Injectable()
export class GitlabService {
  private readonly logger = new Logger(GitlabService.name);
  private readonly baseUrl: string;
  private readonly token: string | undefined;

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {
    // Normalize: strip a trailing slash so we can append `/api/v4/...`.
    const url = this.config.get<string>('GITLAB_URL') ?? 'https://gitlab.com';
    this.baseUrl = url.replace(/\/+$/, '');
    this.token = this.config.get<string>('GITLAB_TOKEN') || undefined;
  }

  /** True when a GITLAB_TOKEN is configured and sync can actually run. */
  get isConfigured(): boolean {
    return Boolean(this.token);
  }

  /** Return the cached repo list (read model for GET /api/gitlab/repos). */
  async listRepos(): Promise<GitlabRepoDto[]> {
    const rows = await this.prisma.gitlabRepo.findMany({
      orderBy: { name: 'asc' },
    });
    return rows.map((r) => ({
      id: r.id,
      gitlabProjectId: r.gitlabProjectId,
      name: r.name,
      path: r.path,
      defaultBranch: r.defaultBranch,
      lastCommitMsg: r.lastCommitMsg,
      syncedAt: r.syncedAt,
      kind: r.kind,
    }));
  }

  /**
   * Trigger a manual sync: pull projects from GitLab and upsert their rows.
   * No token → graceful skip (returns the current cached count, no crash).
   */
  async sync(): Promise<GitlabSyncResultDto> {
    if (!this.isConfigured) {
      this.logger.warn('GITLAB_TOKEN 미설정 — 동기화를 건너뜁니다 (캐시 유지).');
      const cached = await this.prisma.gitlabRepo.count();
      return {
        synced: 0,
        skipped: true,
        message: `GITLAB_TOKEN이 설정되지 않아 동기화를 건너뛰었습니다. 캐시된 저장소 ${cached}개를 유지합니다.`,
      };
    }

    let projects: GitlabProject[];
    try {
      projects = await this.fetchProjects();
    } catch (err) {
      this.logger.error(`GitLab 프로젝트 조회 실패: ${(err as Error).message}`);
      const cached = await this.prisma.gitlabRepo.count();
      return {
        synced: 0,
        skipped: false,
        message: `GitLab 동기화 중 오류가 발생했습니다. 캐시된 저장소 ${cached}개를 유지합니다.`,
      };
    }

    let synced = 0;
    for (const project of projects) {
      try {
        const lastCommitMsg = await this.fetchLastCommitMessage(
          project.id,
          project.default_branch ?? undefined,
        );
        await this.upsertRepo(project, lastCommitMsg);
        synced += 1;
      } catch (err) {
        // One bad project must not abort the whole sync.
        this.logger.warn(
          `프로젝트 동기화 실패 (id=${project.id}): ${(err as Error).message}`,
        );
      }
    }

    return {
      synced,
      skipped: false,
      message: `GitLab 저장소 ${synced}개를 동기화했습니다.`,
    };
  }

  // ──────────────────────────────────────────────
  // Internal GitLab REST helpers (read-only)
  // ──────────────────────────────────────────────

  /** List projects the token can access (membership-scoped, read-only). */
  private async fetchProjects(): Promise<GitlabProject[]> {
    const data = await this.apiGet<GitlabProject[]>(
      '/projects?membership=true&per_page=100&order_by=name&sort=asc',
    );
    return Array.isArray(data) ? data : [];
  }

  /** Last commit message on the default branch (best-effort, may be null). */
  private async fetchLastCommitMessage(
    projectId: number,
    ref?: string,
  ): Promise<string | null> {
    const refQuery = ref ? `&ref_name=${encodeURIComponent(ref)}` : '';
    const commits = await this.apiGet<GitlabCommit[]>(
      `/projects/${projectId}/repository/commits?per_page=1${refQuery}`,
    );
    const latest = Array.isArray(commits) ? commits[0] : undefined;
    if (!latest) {
      return null;
    }
    return latest.title ?? latest.message ?? null;
  }

  /** Upsert a single project into the gitlab_repos cache. */
  private async upsertRepo(
    project: GitlabProject,
    lastCommitMsg: string | null,
  ): Promise<void> {
    const gitlabProjectId = String(project.id);
    const data = {
      gitlabProjectId,
      name: project.name,
      path: project.path_with_namespace,
      defaultBranch: project.default_branch ?? null,
      lastCommitMsg,
      syncedAt: new Date(),
    };
    await this.prisma.gitlabRepo.upsert({
      where: { gitlabProjectId },
      create: data,
      update: data,
    });
  }

  /** Authenticated GET against the GitLab v4 API. */
  private async apiGet<T>(path: string): Promise<T> {
    const res = await fetch(`${this.baseUrl}/api/v4${path}`, {
      headers: { 'PRIVATE-TOKEN': this.token as string },
    });
    if (!res.ok) {
      throw new Error(`GitLab API ${res.status} ${res.statusText} (${path})`);
    }
    return (await res.json()) as T;
  }
}
