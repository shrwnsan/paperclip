import rateLimit from "express-rate-limit";

/**
 * Rate limiter for authentication and access endpoints.
 * Limit: 30 requests per minute per IP
 */
export const authRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute
  standardHeaders: "draft-8", // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  handler: (_req, res) => {
    res.status(429).json({ error: "Too many requests" });
  },
  skip: (req) => {
    // Skip rate limiting for health checks (GET requests to /api/auth/get-session)
    return req.method === "GET" && req.path === "/api/auth/get-session";
  },
});

/**
 * Global rate limiter for general API endpoints.
 * Limit: 300 requests per minute per IP
 * Note: This is not currently applied but available for future use.
 */
export const globalRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 300, // 300 requests per minute
  standardHeaders: "draft-8",
  legacyHeaders: false,
  handler: (_req, res) => {
    res.status(429).json({ error: "Too many requests" });
  },
});
