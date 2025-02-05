export class YupSchemaValidator {
    static async validate(schema: any, payload: any) {
      try {
        await schema.validate(payload, { abortEarly: false });
        return null;
      } catch (error) {
        return error.errors;
      };
    };
};
