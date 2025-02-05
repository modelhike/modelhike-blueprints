
export class InternalResponse {
  result: any;
  error: Error;
  isEmptyData?: boolean;

  static result(result: any): InternalResponse {
    return { result: result, error: null };
  }

  static noData(): InternalResponse {
    return { result: null, error: { statusCode: 404, message: 'Data not found!!' } };
  }

  static emptyData(): InternalResponse {
    return { result: null, error: null, isEmptyData: true };
  }

  static success(): InternalResponse {
    return { result: true, error: null };
  }

  static failure(): InternalResponse {
    return { result: null, error: { statusCode: 504, message: 'Failure!!' } };
  }

  static badRequest(message: string): InternalResponse {
    return { result: null, error: { statusCode: 400, message } };
  }

  static exception(error: any): InternalResponse {
    return { result: null, error: error };
  }
}

export class Error {
  statusCode: number;
  message: string;
}


