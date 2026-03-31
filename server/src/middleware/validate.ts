import type { Request, Response, NextFunction } from "express";
import type { ZodSchema } from "zod";

interface ValidateOptions {
  body?: ZodSchema;
  params?: ZodSchema;
  query?: ZodSchema;
}

export function validate(schema: ZodSchema | ValidateOptions) {
  const isSchema = 'parse' in schema;
  const options = isSchema ? { body: schema } : (schema as ValidateOptions);
  
  return (req: Request, _res: Response, next: NextFunction) => {
    if (options.body) {
      req.body = options.body.parse(req.body);
    }
    if (options.params) {
      req.params = options.params.parse(req.params);
    }
    if (options.query) {
      req.query = options.query.parse(req.query);
    }
    next();
  };
}
