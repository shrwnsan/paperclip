import type { Request, Response, NextFunction } from "express";
import type { ZodSchema } from "zod";

export interface ValidateOptions {
  /** Validate request body */
  body?: ZodSchema;
  /** Validate route parameters */
  params?: ZodSchema;
  /** Validate query parameters */
  query?: ZodSchema;
}

/**
 * Middleware factory for Zod schema validation.
 *
 * Can be called with:
 * - A single schema (validates req.body, for backward compatibility)
 * - A ValidateOptions object (validates body, params, and/or query)
 *
 * Example:
 *   router.post('/items', validate(createItemSchema), handler)
 *   router.get('/items/:id', validate({ params: idParamsSchema, query: listQuerySchema }), handler)
 */
export function validate(schemaOrOptions: ZodSchema | ValidateOptions) {
  // Backward compatibility: if passed a ZodSchema directly, validate body
  const options: ValidateOptions =
    "parse" in schemaOrOptions || "parseAsync" in schemaOrOptions
      ? { body: schemaOrOptions as ZodSchema }
      : (schemaOrOptions as ValidateOptions);

  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      if (options.body) {
        req.body = options.body.parse(req.body);
      }
      if (options.params) {
        req.params = options.params.parse(req.params) as Record<string, string>;
      }
      if (options.query) {
        // Convert query params: Express query can be string | string[] | ParsedQs
        // Zod schemas are built to accept individual string values, so we normalize to string
        const normalizedQuery: Record<string, unknown> = {};
        for (const [key, value] of Object.entries(req.query)) {
          // If it's an array, take the first element (common Express pattern)
          normalizedQuery[key] = Array.isArray(value) ? value[0] : value;
        }
        req.query = options.query.parse(normalizedQuery) as any;
      }
      next();
    } catch (err) {
      next(err);
    }
  };
}
