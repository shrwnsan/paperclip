import type { Request, RequestHandler } from "express";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);
const DEFAULT_DEV_ORIGINS = [
  "http://localhost:3100",
  "http://127.0.0.1:3100",
];

function parseOrigin(value: string | undefined) {
  if (!value) return null;
  try {
    const url = new URL(value);
    return `${url.protocol}//${url.host}`.toLowerCase();
  } catch {
    return null;
  }
}

function trustedOriginsForRequest(configuredOrigins: Set<string>) {
  // If configured origins are provided, use only those (static config)
  if (configuredOrigins.size > 0) {
    return configuredOrigins;
  }
  // Otherwise fall back to default dev origins
  return new Set(DEFAULT_DEV_ORIGINS.map((value) => value.toLowerCase()));
}

function isTrustedBoardMutationRequest(req: Request, configuredOrigins: Set<string>) {
  const allowedOrigins = trustedOriginsForRequest(configuredOrigins);
  const origin = parseOrigin(req.header("origin"));
  if (origin && allowedOrigins.has(origin)) return true;

  const refererOrigin = parseOrigin(req.header("referer"));
  if (refererOrigin && allowedOrigins.has(refererOrigin)) return true;

  return false;
}

export function boardMutationGuard(configuredOrigins: string[] = []): RequestHandler {
  const trustedOrigins = new Set(configuredOrigins.map((value) => value.toLowerCase()));
  
  return (req, res, next) => {
    if (SAFE_METHODS.has(req.method.toUpperCase())) {
      next();
      return;
    }

    if (req.actor.type !== "board") {
      next();
      return;
    }

    // Local-trusted mode and board bearer keys are not browser-session requests.
    // In these modes, origin/referer headers can be absent; do not block those mutations.
    if (req.actor.source === "local_implicit" || req.actor.source === "board_key") {
      next();
      return;
    }

    if (!isTrustedBoardMutationRequest(req, trustedOrigins)) {
      res.status(403).json({ error: "Board mutation requires trusted browser origin" });
      return;
    }

    next();
  };
}
